xquery version "3.1";

import module namespace console="http://exist-db.org/xquery/console";

declare namespace tei="http://www.tei-c.org/ns/1.0";

declare function local:process($docs, $vol-id, $counter) {
    if (exists($docs)) then 
        let $log := if ($counter mod 100 = 0) then console:log($vol-id || ": starting doc " || $counter) else ()
        let $doc := head($docs)
        let $doc-id := $doc/@xml:id
        let $date := ($doc//tei:date)[1]
        let $entry := 
            <date-entry>
                <source-id>frus:{$vol-id/string()}/{$doc-id/string()}</source-id>
                <original-text>{$date//text()[not(./ancestor::tei:note)] ! normalize-space(string-join(.))}</original-text>
                <when>{$date/@when/string()}</when>
                <from>{$date/@from/string()}</from>
                <to>{$date/@to/string()}</to>
                <notBefore>{$date/@notBefore/string()}</notBefore>
                <notAfter>{$date/@notAfter/string()}</notAfter>
                <ana>{$date/@ana/string()}</ana>
            </date-entry>
        let $store := xmldb:store("/db/frus-dates-import/" || $vol-id,  $doc-id || ".xml", $entry)
        return
            local:process(tail($docs), $vol-id, $counter + 1)
    else 
        $vol-id || "all done: " || $counter - 1 || " records processed"
};

let $reset := true()
let $dates-col-name := "frus-dates"
let $dates-col := "/db/apps/" || $dates-col-name
let $dates-import-col := "/db/" || $dates-col-name || "-import"
let $prepare := 
    if ($reset and xmldb:collection-available($dates-import-col)) then
        xmldb:remove($dates-import-col)
    else
        ()
let $create := 
    (
        xmldb:create-collection("/db", $dates-col-name),
        xmldb:create-collection("/db", $dates-col-name || "-import")
    )

for $vol in collection('/db/apps/frus/volumes')
let $docs := $vol//tei:div[@type eq 'document'][.//tei:date]
let $vol-id := $vol/tei:TEI/@xml:id
let $create := xmldb:create-collection($dates-import-col, $vol-id)
return
    local:process($docs, $vol-id, 1)