xquery version "3.1";

import module namespace functx="http://www.functx.com" at "/db/system/repo/functx-1.0/functx/functx.xql";

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

let $query-start := util:system-time()
let $timezone := xs:dayTimeDuration('PT0H')
let $start := 
    '1941-12-07' 
    (:
    '1934-03'
    :)
    => local:normalize-low($timezone)
let $end := 
    '1945-08-15' 
    (:
    '1934-03'
    :)
    => local:normalize-high($timezone)
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