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
    for $hit in
        (: "0.387s" with combined range index - see http://exist-db.org/exist/apps/doc/newrangeindex.xml :)
        collection('/db/apps/frus-dates/data')//date-entry[date-min/@utc ge $start and date-max/@utc le $end]
        (:
        :)
        (:
        "3.645s" with just new range index
        :)
        (:
        collection('/db/frus-dates/data')//date-entry[range:ge(date-min/@utc, $start)][range:le(date-max/@utc, $end)]
        :)
        
        (:
        err:XPTY0004 can not compare xs:string('1865-04-28T00:00:00Z') with xs:dateTime('1941-12-07T00:00:00Z')
        :)
        (:
        (
            collection('/db/frus-dates/data')//date-min[@utc ge $start]/..
            union
            collection('/db/frus-dates/data')//date-max[@utc le $end]/..
        )
        :)
    let $sort := $hit/date-min/@utc
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