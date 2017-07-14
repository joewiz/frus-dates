xquery version "3.1";

import module namespace fd="http://history.state.gov/ns/site/hsg/frus-dates" at "../modules/frus-dates.xqm";

declare function local:normalize($e as element()) {
    if ($e ne '') then
        let $timezone := xs:dayTimeDuration('PT0H')
        let $normalized :=
            if ($e instance of element(when) or $e instance of element(from) or $e instance of element(notBefore)) then
                fd:normalize-low($e, $timezone)
            else
                fd:normalize-high($e, $timezone)
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

for $d in collection('/db/apps/frus-dates/data')//(when | from | to | notBefore | notAfter)[. ne ''][not(@utc)]
return
    update replace $d with local:normalize($d)