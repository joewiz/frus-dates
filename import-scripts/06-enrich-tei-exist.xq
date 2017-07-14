xquery version "3.1";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace frus="http://history.state.gov/frus/ns/1.0";

import module namespace console="http://exist-db.org/xquery/console" at "java:org.exist.console.xquery.ConsoleModule";
import module namespace fd="http://history.state.gov/ns/site/hsg/frus-dates" at "/db/apps/frus-dates/modules/frus-dates.xqm";

let $timezone := xs:dayTimeDuration('PT0H')
for $vol in collection("/db/frus-volumes")
let $vol-id := $vol/tei:TEI/@xml:id
let $docs := $vol//tei:div[@type="document"]
let $log := console:log("starting " || $vol-id || ": " || count($docs) || " documents")
for $doc in $docs
let $dateline := ($doc//tei:dateline[.//tei:date])[1]
let $date := ($dateline//tei:date)[1]
let $min := ($date/@from, $date/@notBefore, $date/@when)[1]
let $max := ($date/@to, $date/@notAfter, $date/@when)[1]
let $dateTime-min := if ($min and not($doc/@dateTime-min)) then attribute frus:doc-dateTime-min { fd:normalize-low($min, $timezone) } else ()
let $dateTime-max := if ($max and not($doc/@dateTime-max)) then attribute frus:doc-dateTime-max { fd:normalize-high($max, $timezone) } else ()
return
    if (exists($min) or exists($max)) then 
        update insert ($dateTime-min, $dateTime-max) into $doc 
    else 
        ()