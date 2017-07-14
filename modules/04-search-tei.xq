xquery version "3.1";

declare namespace tei="http://www.tei-c.org/ns/1.0";

let $hits := collection("/db/apps/frus/volumes")//tei:div[@dateTime-min gt xs:dateTime("1971-01-01T00:00:00Z") and @dateTime-max lt xs:dateTime("1971-12-31T00:00:00Z")][ft:query(., "china")]
let $start := 1
let $end := 10
let $hits-to-show := subsequence($hits, $start, $end)
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
let $date-string := $date/string() => normalize-space()
let $placeName := ($doc//tei:placeName)[1]
let $placeName-string := $placeName//text()[not(./ancestor::tei:note)] => string-join() => normalize-space()
let $source-date-string := $date//text()[not(./ancestor::tei:note)] => string-join() => normalize-space()
let $calendar := $date/@calendar/string()
let $ana := $date/@ana/string()
return
    <div>
        <p>{$n}. <a href="{$vol-id || "/" || $doc-id}">{$heading-stripped}</a></p>
        <ul>
            <li>Original Date: {$date-string}</li>
            <li>Original Place: {$placeName-string}</li>
            <li>Analyzed Date: <code>{serialize(element date {$date/@*})}</code></li>
        </ul>
    </div>