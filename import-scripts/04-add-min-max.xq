xquery version "3.1";

import module namespace fd="http://history.state.gov/ns/site/hsg/frus-dates" at "../modules/frus-dates.xqm";

let $timezone := xs:dayTimeDuration('PT0H')
for $d in collection('/db/apps/frus-dates/data')//date-entry[not(date-min)]
let $min := ($d/from/@utc, $d/notBefore/@utc, $d/when/@utc)[1]
let $max := ($d/to/@utc, $d/notAfter/@utc, if ($d/when/@utc) then fd:normalize-high($d/when, $timezone) else ())[1]
let $new-elements := 
    if (exists($min) and exists($max)) then (element date-min { attribute utc { $min } }, element date-max { attribute utc { $max } }) else (element date-min { () }, element date-max { () })
return
    update insert $new-elements into $d