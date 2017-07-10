xquery version "3.1";

import module namespace functx="http://www.functx.com" at "/db/system/repo/functx-1.0/functx/functx.xql";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace tei="http://www.tei-c.org/ns/1.0";

declare option output:method "html5";
declare option output:media-type "text/html";

declare variable $local:app-base := "/exist/apps/frus-dates/index.xq";


declare function local:normalize-low($date as xs:string, $timezone as xs:dayTimeDuration) {
    let $dateTime :=
        if ($date castable as xs:dateTime) then 
            adjust-dateTime-to-timezone(xs:dateTime($date), $timezone)
        else if ($date castable as xs:date) then
            let $adjusted-date := adjust-date-to-timezone(xs:date($date), $timezone)
            return
                substring($adjusted-date, 1, 10) || 'T00:00:00' || substring($adjusted-date, 11)
        else if (matches($date, '^\d{4}-\d{2}$')) then
            adjust-dateTime-to-timezone(xs:dateTime($date || '-01T00:00:00'), $timezone)
        else (: if (matches($date, '^\d{4}$')) then :)
            adjust-dateTime-to-timezone(xs:dateTime($date || '-01-01T00:00:00'), $timezone)
    return
        $dateTime cast as xs:dateTime
};

declare function local:normalize-high($date as xs:string, $timezone as xs:dayTimeDuration) as xs:dateTime {
    let $dateTime :=
        if ($date castable as xs:dateTime) then 
            adjust-dateTime-to-timezone(xs:dateTime($date), $timezone)
        else if ($date castable as xs:date) then
            let $adjusted-date := adjust-date-to-timezone(xs:date($date), $timezone)
            return
                substring($adjusted-date, 1, 10) || 'T23:59:59' || substring($adjusted-date, 11)
        else if (matches($date, '^\d{4}-\d{2}$')) then
            adjust-dateTime-to-timezone(xs:dateTime($date || '-' || functx:days-in-month($date || '-01') || 'T23:59:59'), $timezone)
        else (: if (matches($date, '^\d{4}$')) then :)
            adjust-dateTime-to-timezone(xs:dateTime($date || '-12-31T23:59:59'), $timezone)
    return
        $dateTime cast as xs:dateTime
};

declare function local:wrap-html($content as element(), $title as xs:string+) {
    <html>
        <head>
            <title>{string-join(reverse($title), ' | ')}</title>
            <link href="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/css/bootstrap.min.css" rel="stylesheet"/>
            <script src="https://ajax.googleapis.com/ajax/libs/jquery/1.11.3/jquery.min.js"></script>
            <script src="https://maxcdn.bootstrapcdn.com/bootstrap/3.3.5/js/bootstrap.min.js"></script>
            <style type="text/css">
                body {{ font-family: HelveticaNeue, Helvetica, Arial, sans }}
                table {{ page-break-inside: avoid }}
                dl {{ margin-above: 1em }}
                dt {{ font-weight: bold }}
            </style>
            <style type="text/css" media="print">
                a, a:visited {{ text-decoration: underline; color: #428bca; }}
                a[href]:after {{ content: "" }}
            </style>
        </head>
        <body>
            <div class="container">
                <h3><a href="{$local:app-base}">{$title[1]}</a></h3>
                {$content}
            </div>
        </body>
    </html>    
};

let $title := "FRUS Dates Proof of Concept"
let $doc-count := 233686 (: count(collection("/db/apps/frus/volumes")//tei:div[@type="document"]) :)
let $dated-doc-count := 222534 (: count(collection("/db/apps/frus-dates/data")//date-min[@utc]) :)
let $date := request:get-parameter("date", ())
let $start-date := request:get-parameter("start-date", ())
let $end-date := request:get-parameter("end-date", ())
let $query-start := util:system-time()
let $timezone := xs:dayTimeDuration("PT0H")
let $start := 
    if ($date ne "") then
        $date => local:normalize-low($timezone)
    else if ($start-date ne "") then
        $start-date => local:normalize-low($timezone)
    else
        ()
let $end := 
    if ($date ne "") then
        $date => local:normalize-high($timezone)
    else if ($end-date ne "") then
        $end-date => local:normalize-high($timezone)
    else
        ()
let $hits :=
    if (exists($start) and exists($end)) then
        for $hit in collection('/db/frus-dates/data')//date-entry[date-min/@utc ge $start and date-max/@utc le $end]
        let $sort := $hit/date-min/@utc
        order by $sort
        return $hit
    else ()
let $hits-to-show := subsequence($hits, 1, 10)
let $query-end := util:system-time()
let $query-duration := ($query-end - $query-start) div xs:dayTimeDuration("PT1S") || "s"
let $content := 
    <div>
        <p>The FRUS repository contains {format-number($doc-count, "#,###.##")} documents, {format-number($dated-doc-count, "#,###.##")} of which have dates. 
            (Thus, {format-number($doc-count - $dated-doc-count, "#,###.##")} do not have dates; of these, some are editorial notes, others are undated documents whose dates are still being researched.)
            This app is a demonstration of the kinds of queries we can perform on these dates.
        </p>
        <p>To get started, try an example query: <a href="?date=1941">1941</a>; <a href="?date=1941-12">December 1941</a>; <a href="?date=1941-12-07">December 7, 1941</a>; <a href="?start-date=1968-11-05&amp;end-date=1969-01-20">the period between the election and inauguration of Richard Nixon</a>; <a href="?start-date=1969-01-20&amp;end-date=1974-08-09">the Nixon administration</a>; and <a href="?start-date=1974-08-09T10:00:00&amp;end-date=1974-08-09T20:00:00">August 8, 1974, 10 a.m.–8 p.m.</a></p>
        <p>To craft your own query, enter either a single date or a date range. A future version will add a calendar widget, but for now, use the following date format: <code>YYYY</code>, <code>YYYY-MM</code>, <code>YYYY-MM-DD</code>. Times can be added too, appending <code>T</code> followed by the time <code>HH:MM:SS</code> and optional time zone <code>Z</code> or <code>±HH:MM</code>. For example, <code>1945-08-15T20:00:00</code> describes August 15, 1945 at 8 p.m.</p>
        <form class="form-inline" action="{$local:app-base}" method="get">
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
            <a type="button" href="{$local:app-base}" class="btn btn-default">Clear</a>
        </form>
        {
            if ($hits) then
                (
                <hr/>,
                <div>
                    <p>Search completed in {$query-duration}. Showing 1-{format-number(count($hits-to-show), "#,###.##")} of {format-number(count($hits), "#,###.##")} documents matching search dated between {$start} and {$end} (duration: {$end - $start}):</p>
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
    local:wrap-html($content, $title)