xquery version "3.1";

import module namespace functx="http://www.functx.com" at "/db/system/repo/functx-1.0/functx/functx.xql";

declare function local:normalize-low($date as xs:string, $timezone as xs:dayTimeDuration) {
    if ($date castable as xs:dateTime) then 
        adjust-dateTime-to-timezone(xs:dateTime($date), $timezone)
    else if ($date castable as xs:date) then
        let $adjusted-date := adjust-date-to-timezone(xs:date($date), $timezone)
        return
            substring($adjusted-date, 1, 10) || 'T00:00:00' || substring($adjusted-date, 11)
    else if (matches($date, '^\d{4}-\d{2}$')) then
        adjust-dateTime-to-timezone(xs:dateTime($date || '-01T00:00:00'), $timezone)
    else (: if (matches($e, '^\d{4}$')) then :)
        adjust-dateTime-to-timezone(xs:dateTime($date || '-01-01T00:00:00'), $timezone)
};

declare function local:normalize-high($date as xs:string, $timezone as xs:dayTimeDuration) {
    if ($date castable as xs:dateTime) then 
        adjust-dateTime-to-timezone(xs:dateTime($date), $timezone)
    else if ($date castable as xs:date) then
        let $adjusted-date := adjust-date-to-timezone(xs:date($date), $timezone)
        return
            substring($adjusted-date, 1, 10) || 'T23:59:59' || substring($adjusted-date, 11)
    else if (matches($date, '^\d{4}-\d{2}$')) then
        adjust-dateTime-to-timezone(xs:dateTime($date || '-' || functx:days-in-month($date || '-01') || 'T23:59:59'), $timezone)
    else (: if (matches($e, '^\d{4}$')) then :)
        adjust-dateTime-to-timezone(xs:dateTime($date || '-12-' || functx:days-in-month($date || '-12-01') || 'T23:59:59'), $timezone)
};

declare function local:normalize($e as element()) {
    if ($e ne '') then
        let $timezone := xs:dayTimeDuration('PT0H')
        let $normalized :=
            if ($e instance of element(when) or $e instance of element(from) or $e instance of element(notBefore)) then
                local:normalize-low($e, $timezone)
            else
                local:normalize-high($e, $timezone)
        return
            element { $e/node-name(.) } { attribute utc { $normalized }, $e/node() }
    else 
        $e
};

declare function local:check-for-errors() {
    for $date in collection('/db/apps/frus-dates/data')//(when | from | to | notBefore | notAfter)[. ne '']
    let $normalize := 
        try 
            {
                local:normalize($date)
            } 
        catch * 
            { 
                <response status="fail">
                    <message>There was an unexpected problem. {concat($err:code, ": ", $err:description, ' (', $err:module, ' ', $err:line-number, ':', $err:column-number, ')')}</message>
                    {$date/..}
                </response>
            }
    return
        if ($normalize/self::response) then $normalize else ()
};

(: 
local:check-for-errors()
:)

let $timezone := xs:dayTimeDuration('PT0H')
for $d in collection('/db/apps/frus-dates/data')//date-entry[not(date-min)]
let $min := ($d/from/@utc, $d/notBefore/@utc, $d/when/@utc)[1]
let $max := ($d/to/@utc, $d/notAfter/@utc, if ($d/when/@utc) then local:normalize-high($d/when, $timezone) else ())[1]
let $new-elements := 
    if (exists($min) and exists($max)) then (element date-min { attribute utc { $min } }, element date-max { attribute utc { $max } }) else (element date-min { () }, element date-max { () })
return
    update insert $new-elements into $d