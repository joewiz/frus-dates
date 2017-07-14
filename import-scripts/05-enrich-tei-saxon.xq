xquery version "3.1";

(: collection-wide version died in oXygen with out of memory errors before any files were written. 
   switching to eXist to see if I have better luck there :)

declare namespace tei="http://www.tei-c.org/ns/1.0";

import module namespace fd="http://history.state.gov/ns/site/hsg/frus-dates" at "../modules/frus-dates.xqm";

let $timezone := xs:dayTimeDuration('PT0H')
let $vol := 
    (: doc("file:/Users/joe/workspace/hsg-project/repos/frus/volumes/frus1969-76v18.xml") :)
    collection("file:/Users/joe/workspace/hsg-project/repos/frus/volumes/?select=*.xml")
let $docs := $vol//tei:div[@type="document"]
for $doc in $docs
let $dateline := ($doc//tei:dateline[.//tei:date])[1]
let $date := ($dateline//tei:date)[1]
let $min := ($date/@from, $date/@notBefore, $date/@when)[1]
let $max := ($date/@to, $date/@notAfter, $date/@when)[1]
let $dateTime-min := if ($min and not($doc/@dateTime-min)) then attribute dateTime-min { fd:normalize-low($min, $timezone) } else ()
let $dateTime-max := if ($max and not($doc/@dateTime-max)) then attribute dateTime-max { fd:normalize-high($max, $timezone) } else ()
return
    if (exists($min) or exists($max)) then 
        insert nodes ($dateTime-min, $dateTime-max) into $doc 
    else 
        ()