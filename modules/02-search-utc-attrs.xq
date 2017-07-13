xquery version "3.1";

import module namespace fd="http://history.state.gov/ns/site/hsg/frus-dates" at "../modules/frus-dates.xqm";
import module namespace functx="http://www.functx.com";

let $query-start := util:system-time()
let $timezone := xs:dayTimeDuration('PT0H')
let $start := 
    '1941-12-07' 
    (:
    '1934-03'
    :)
    => fd:normalize-low($timezone)
let $end := 
    '1945-08-15' 
    (:
    '1934-03'
    :)
    => fd:normalize-high($timezone)
let $hits :=
    for $hit in collection('/db/apps/frus-dates/data')//date-entry
        [
            (
                (: regular ge complains of xs:string comparison :)
                range:ge(when/@utc, $start) and range:le(when/@utc, $end)
            )
            or
            (
                range:ge(from/@utc, $start) and range:le(to/@utc, $end)
            )
            or
            (
                range:ge(notBefore/@utc, $start) and range:le(notAfter/@utc, $end)
            )
            (:
            :)
        ]
    let $sort := ($hit/from/@utc, $hit/notBefore/@utc, $hit/when/@utc)[1]
    (:
    :)
    order by $sort descending
    return $hit
let $query-end := util:system-time()
let $query-duration := ($query-end - $query-start) div xs:dayTimeDuration("PT1S") || "s"
return
    (
        map { "start": $start, "end": $end, "hits-count": count($hits), "query-duration": $query-duration }
        ,
        $hits
    )