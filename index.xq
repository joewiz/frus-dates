xquery version "3.1";

import module namespace fd="http://history.state.gov/ns/site/hsg/frus-dates" at "modules/frus-dates.xqm";
import module namespace functx="http://www.functx.com";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare option output:method "html5";
declare option output:media-type "text/html";

let $title := "FRUS Dates Proof of Concept"
let $doc-count := count(collection("/db/apps/frus/volumes")//tei:div[@type="document"])
let $dated-doc-count := count(collection("/db/apps/frus-dates/data")//date-min[@utc])
let $date := request:get-parameter("date", ())
let $start-date := request:get-parameter("start-date", ())
let $end-date := request:get-parameter("end-date", ())
let $query-start := util:system-time()
let $timezone := 
    (: We want to assume times supplied in a query are US Eastern, unless otherwise specified. 
       The UTC offset for US Eastern changes depending on daylight savings time.
       We could use fn:implicit-timezone(), but this depends upon the query context, which is set by the system/environment.
       On the hsg production servers, this function returns +00:00, or UTC. 
       So the following is a kludge to determine the UTC offset for US Eastern, sensitive to daylight savings time. :)
    functx:duration-from-timezone(fn:format-dateTime(current-dateTime(), "[Z]", (), (), "America/New_York"))
let $start := 
    if ($date ne "") then
        $date => fd:normalize-low($timezone)
    else if ($start-date ne "") then
        $start-date => fd:normalize-low($timezone)
    else
        ()
let $end := 
    if ($date ne "") then
        $date => fd:normalize-high($timezone)
    else if ($end-date ne "") then
        $end-date => fd:normalize-high($timezone)
    else
        ()
let $hits :=
    if (exists($start) and exists($end)) then
        for $hit in collection('/db/apps/frus-dates/data')//date-entry[date-min/@utc ge $start and date-max/@utc le $end]
        let $sort := $hit/date-min/@utc
        order by $sort
        return $hit
    else ()
let $hits-to-show := subsequence($hits, 1, 10)
let $query-end := util:system-time()
let $query-duration := ($query-end - $query-start) div xs:dayTimeDuration("PT1S") || "s"
let $content := 
    <div>
        <p>As of {format-dateTime(doc('/db/apps/frus-dates/data/frus-dates.xml')/date-entries/created-dateTime, '[MNn] [D], [Y0001]', 'en', (), 'US')}, the <em>FRUS</em> digital archive contains {format-number($doc-count, "#,###.##")} documents, {format-number($dated-doc-count, "#,###.##")} of which have dates. 
            (Thus, {format-number($doc-count - $dated-doc-count, "#,###.##")} do not have dates; of these, some are editorial notes, others are undated documents whose dates are still being researched.)
            This app is a demonstration of the kinds of queries we can perform on these dates.
        </p>
        <p>To get started, try one of the following example queries: <a href="?date=1941">1941</a>; <a href="?date=1941-12">December 1941</a>; <a href="?date=1941-12-07">December 7, 1941</a>; <a href="?start-date=1968-11-05&amp;end-date=1969-01-20">the period between the election and inauguration of Richard Nixon</a>; <a href="?start-date=1969-01-20&amp;end-date=1974-08-09">the Nixon administration</a>; and <a href="?start-date=1974-08-09T10:00:00&amp;end-date=1974-08-09T20:00:00">August 9, 1974, 10 a.m.–8 p.m.</a></p>
        <p>To craft your own query, enter either a single date or a date range. A future version will add a calendar widget, but for now, use the following date format: <code>YYYY</code>, <code>YYYY-MM</code>, <code>YYYY-MM-DD</code>. Times can be added too, appending <code>T</code> followed by the time <code>HH:MM:SS</code> and optional time zone <code>Z</code> or <code>±HH:MM</code>. Unless otherwise specified, your query is assumed to be in US Eastern time, though you may experience some slight timezone misalignment in cases when our conversion vendor didn’t complete UTC offsets for dates, a deficiency we plan to correct. For example, <code>1945-08-15T20:00:00</code> describes August 15, 1945 at 8 p.m. US Eastern, whereas <code>1945-08-15T20:00:00Z</code> is 8 p.m. UTC, or 3 or 4 p.m. US Eastern depending on daylight savings time.</p>
        <form class="form-inline" action="{$fd:app-base}" method="get">
            <div class="form-group">
                <label for="date" class="control-label">Date</label>
                <input type="text" name="date" id="date" class="form-control" value="{$date}"/>
            </div>
            <br/>
            <div class="form-group">
                <label for="start-date" class="control-label">Start</label>
                <input type="text" name="start-date" id="start-date" class="form-control" value="{$start-date}"/>
            </div>
            <div class="form-group">
                <label for="end-date" class="control-label">End</label>
                <input type="text" name="end-date" id="end-date" class="form-control" value="{$end-date}"/>
            </div>
            <br/>
            <button type="submit" class="btn btn-default">Submit</button>
            <a type="button" href="{$fd:app-base}" class="btn btn-default">Clear</a>
        </form>
        {
            if ($hits) then
                (
                <hr/>,
                <div>
                    <p>Search completed in {$query-duration}. Showing 1-{format-number(count($hits-to-show), "#,###.##")} of {format-number(count($hits), "#,###.##")} documents matching search dated between <code>{$start}</code> and <code>{$end}</code> (duration: {$end - $start}):</p>
                    <ol>
                        {
                            for $hit in $hits-to-show
                            let $slug := substring-after($hit/source-id, "frus:")
                            let $summary := 
                                <pre>{serialize($hit, <output:options><output:indent>yes</output:indent></output:options>)}</pre>
                            return
                                <li><a href="https://history.state.gov/historicaldocuments/{$slug}">{$slug}</a>{$summary}</li>
                        }
                    </ol>
                </div>
                )
            else
                ()
        }
    </div>
return
    fd:wrap-html($content, $title)
