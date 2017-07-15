xquery version "3.1";

import module namespace console="http://exist-db.org/xquery/console";
import module namespace fd="http://history.state.gov/ns/site/hsg/frus-dates" at "/db/apps/frus-dates/modules/frus-dates.xqm";
import module namespace functx="http://www.functx.com";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace frus="http://history.state.gov/frus/ns/1.0";

declare option output:method "html5";
declare option output:media-type "text/html";

let $title := "FRUS Dates Proof of Concept"
let $doc-count := 233686
    (:count(collection("/db/apps/frus/volumes")//tei:div[@type="document"]):)
let $dated-doc-count := 220949
    (:count(collection("/db/apps/frus/volumes")//tei:div[@type="document"][@frus:doc-dateTime-min]):)
let $docs-counted-date := xs:date("2017-07-14")
let $start-date := request:get-parameter("start-date", ())
let $start-time := request:get-parameter("start-time", ())
let $end-date := request:get-parameter("end-date", ())
let $end-time := request:get-parameter("end-time", ())
let $q := request:get-parameter("q", ())[. ne ""]
let $start := request:get-parameter("start", 1) cast as xs:integer
let $per-page := request:get-parameter("per-page", 10) cast as xs:integer
let $query-start := util:system-time()
let $timezone := 
    (: We want to assume times supplied in a query are US Eastern, unless otherwise specified. 
       The UTC offset for US Eastern changes depending on daylight savings time.
       We could use fn:implicit-timezone(), but this depends upon the query context, which is set by the system/environment.
       On the hsg production servers, this function returns +00:00, or UTC. 
       So the following is a kludge to determine the UTC offset for US Eastern, sensitive to daylight savings time. :)
    functx:duration-from-timezone(fn:format-dateTime(current-dateTime(), "[Z]", (), (), "America/New_York"))
let $range-start := 
    if ($start-date ne "") then
        ($start-date || (if ($start-time ne "") then ("T" || $start-time) else ()))
            => fd:normalize-low($timezone)
    else
        ()
let $range-end := 
    if ($end-date ne "") then
        ($end-date || (if ($end-time ne "") then ("T" || $end-time) else ()))
            => fd:normalize-high($timezone)
    else if ($start-date ne "") then
        ($start-date || (if ($start-time ne "") then ("T" || $start-time) else ()))
            => fd:normalize-high($timezone)
    else
        ()
let $log := console:log("starting search for " || " start-date=" || $start-date || " (range-start=" || $range-start || ") end-date=" || $end-date || " (range-end=" || $range-end || ") q=" || $q)
let $hits :=
    if (exists($range-start) and exists($range-end) and exists($q)) then
        collection("/db/apps/frus/volumes")//tei:div[@frus:doc-dateTime-min ge $range-start and @frus:doc-dateTime-max le $range-end][ft:query(., $q)]
    else if (exists($range-start) and exists($range-end)) then
        collection("/db/apps/frus/volumes")//tei:div[@frus:doc-dateTime-min ge $range-start and @frus:doc-dateTime-max le $range-end]
    else if (exists($q)) then
        collection("/db/apps/frus/volumes")//tei:div[ft:query(., $q)]
    else 
        ()
let $ordered-hits := 
    for $doc in $hits
    order by $doc/@frus:doc-dateTime-min
    return $doc
let $query-end := util:system-time()
let $query-duration := ($query-end - $query-start) div xs:dayTimeDuration("PT1S") || "s"
let $end := $start + $per-page - 1
let $hits-to-show := subsequence($ordered-hits, $start, $per-page)
let $link-to-next := 
    <a href="{
        let $url := request:get-query-string()
        return
            if (matches($url, "start=\d")) then
                "?" || replace($url, "start=\d+", "start=" || $end + 1)
            else 
                "?" || $url || "&amp;start=" || $end + 1
    }">Next {$per-page} results.</a>
let $content :=
    <div>
        <p>Since its launch, the <em>FRUS</em> digital archive offered series-wide full-text search, but it lacked date-based search or chronological sorting of search results. This was a highly requested feature, but without reliable machine-readable dates, it was technically infeasible. Instead, we defered this feature and focused on other goals—most importantly, completing the digitization of the print archive. Now, with over 400 of the 550+ volumes digitized in TEI XML, we now have a representative sample of the variety of document dates in <em>FRUS</em> suitable for thorough review and analysis.</p>
        <p>In October 2016 the Office’s digital initiatives team launched a project to review dates across the series. In July 2017 the project achieved a major milestone: the completion of dates in all <em>FRUS</em> volumes released before 2017. Now, as of {format-date($docs-counted-date, '[MNn] [D], [Y0001]', 'en', (), 'US')}, {format-number($dated-doc-count, "#,###.##")} of the {format-number($doc-count, "#,###.##")} documents ({round($dated-doc-count div $doc-count * 1000) div 10}% of the archive) contain machine-readable dates in a format suitable for date-based searching and sorting. (Research on the remaining {format-number($doc-count - $dated-doc-count, "#,###.##")} documents is ongoing.) 
        Now, we are preparing to integrate this data into the history.state.gov’s search interface. This page is an early attempt at demonstrating the viability of querying the dates. Please give it a try and <a href="https://history.state.gov/about/contact-us">let us know</a> what you think.</p>
        <p>To get started, click on one of the following example queries to see the results: <a href="?start-date=1941-12-07">December 7, 1941</a>; <a href="?start-date=1969-01-20&amp;end-date=1974-08-09">the Nixon administration</a>; <a href="?start-date=1974-08-09&amp;start-time=10:00&amp;end-date=1974-08-09&amp;end-time=20:00">August 9, 1974, 10 a.m.–8 p.m.</a>; <a href="?start-date=1977-01-20&amp;end-date=1981-01-20&amp;q=""human+rights""">“Human Rights” during the Carter administration</a>.</p>
        <p>To craft your own query, enter either a single date to find documents from that date, or use two dates to search for all documents between those dates (inclusive). Times can be added for more precision. (A note on time zones: Unless otherwise specified, your query is assumed to be in US Eastern time, though you may experience some slight timezone misalignment that we are investigating.) You can also add a keyword to your search, using the same syntax as described on <a href="https://history.state.gov/search/tips">history.state.gov/search/tips</a>.</p>
        <form class="form-inline" action="{$fd:app-base}" method="get">
            <h4 class="bg-info">1. Enter a date to find documents from that date. Specifying a time is optional.</h4>
            <div class="form-group">
                <label for="start-date" class="control-label">Start Date</label>
                <input type="date" name="start-date" id="start-date" class="form-control" value="{$start-date}"/>
            </div>
            <div class="form-group">
                <label for="start-time" class="control-label">Time</label>
                <input type="time" name="start-time" id="start-time" class="form-control" value="{$start-time}"/>
            </div>
            <h4 class="bg-info">2: Optionally, specify an “end date” to extend your search across a range of dates. Otherwise, the search will return documents from just the “start date.”</h4>
            <div class="form-group">
                <label for="end-date" class="control-label">End Date</label>
                <input type="date" name="end-date" id="end-date" class="form-control" value="{$end-date}"/>
            </div>
            <div class="form-group">
                <label for="end-time" class="control-label">Time (optional)</label>
                <input type="time" name="end-time" id="end-time" class="form-control" value="{$end-time}"/>
            </div>
            <h4 class="bg-info">3. Optionally, enter keywords to target specific topics or terms.</h4>
            <div class="form-group">
                <label for="q" class="control-label">Keyword</label>
                <input type="text" name="q" id="q" class="form-control" value="{$q}"/>
            </div>
            <br/>
            <button type="submit" class="btn btn-default">Submit</button>
            <a type="button" href="{$fd:app-base}" class="btn btn-default">Clear</a>
        </form>
        {
            if (exists($hits)) then
                (
                <hr/>,
                <div>
                    <p>Search completed in {$query-duration}. Showing {format-number($start, "#,###.##")}-{format-number($end, "#,###.##")} of {format-number(count($hits), "#,###.##")} documents {
                        let $date-summary := 
                            if (exists($range-start) and exists($range-end)) then 
                                (
                                    "dated between ", 
                                    <code>{$range-start}</code>, 
                                    " and ", 
                                    <code>{$range-end}</code>, 
                                    " (duration: ", 
                                    $range-end - $range-start, 
                                    ")"
                                )
                            else 
                                ()
                        let $q-summary := 
                            if (exists($q)) then 
                                (
                                    "with keyword ",
                                    <code>{$q}</code>
                                )
                            else 
                                ()
                        return
                            (
                                if (exists($range-start) and exists($range-end) and exists($q-summary)) then
                                    ($date-summary, " and ", $q-summary)
                                else if (exists($range-start) and exists($range-end)) then
                                    $date-summary
                                else if (exists($q)) then
                                    $q-summary
                                else ()
                                , 
                                ", sorted in chronological order. "
                                ,
                                $link-to-next
                            )
                    }</p>
                    {
                        for $doc at $n in $hits-to-show
                        let $doc-id := $doc/@xml:id
                        let $vol-id := root($doc)/tei:TEI/@xml:id
                        let $heading := ($doc//tei:head)[1]
                        let $heading-string := 
                            if ($heading ne '') then 
                                $heading//text()[not(./ancestor::tei:note)] 
                                    => string-join() 
                                    => normalize-space()
                            else 
                                ()
                        let $heading-stripped := 
                            if (matches($heading-string, ('^' || $doc/@n || '\.'))) then 
                                replace($heading-string, '^' || $doc/@n || '\.\s+(.+)$', '$1') 
                            else 
                                $heading-string
                        let $dateline := ($doc//tei:dateline[.//tei:date])[1]
                        let $date := ($dateline//tei:date)[1]
                        let $date-string := $date//text()[not(./ancestor::tei:note)] => string-join() => normalize-space()
                        let $placeName := ($doc//tei:placeName)[1]
                        let $placeName-string := $placeName//text()[not(./ancestor::tei:note)] => string-join() => normalize-space()
                        return
                            <div>
                                <p>{$start + $n - 1}. <a href="https://history.state.gov/historicaldocuments/{$vol-id || "/" || $doc-id}">{$heading-stripped}</a></p>
                                <dl class="dl-horizontal">
                                    <dt>Recorded Date</dt><dd>{$date-string}</dd>
                                    <dt>Recorded Location</dt><dd>{$placeName-string}</dd>
                                    <dt>Encoded Date</dt><dd><code>{serialize(element date {$date/@*})}</code></dd>
                                    <dt>Document ID</dt><dd>{$vol-id/string()}/{$doc-id/string()}</dd>
                                </dl>
                            </div>
                    }
                    <p>{ $link-to-next }</p>
                </div>
                )
            else if ($start-date or $end-date or $q) then
                <p>No hits found.</p>
            else 
                ()
        }
    </div>
return
    fd:wrap-html($content, $title)
