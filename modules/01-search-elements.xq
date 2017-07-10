xquery version "3.1";

let $start := '1941-12-07'
let $end := '1945-08-15'
for $hit in collection('/db/apps/frus-dates/data')//date-entry
    [
        (
            range:ge(when, $start) and range:le(when, $end)
        )
        or
        (
            range:ge(from, $start) and range:le(to, $end)
        )
        or
        (
            range:ge(notBefore, $start) and range:le(notAfter, $end)
        )
    ]
let $sort := ($hit/from, $hit/notBefore, $hit/when)[. ne ''][1]
order by $sort
return $hit