xquery version "3.1";

let $entries := 
    element date-entries { 
        element created-dateTime { current-dateTime() }, 
        for $e in collection("/db/frus-dates-import")//date-entry order by base-uri($e) return $e
    }
return
    xmldb:store("/db/apps/frus-dates/data", "frus-dates.xml", $entries)