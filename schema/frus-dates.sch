<?xml version="1.0" encoding="UTF-8"?>
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2"
    xmlns:sqf="http://www.schematron-quickfix.com/validator/process">
    <sch:pattern>
        <sch:rule context="date-entry">
            <sch:assert test="when ne '' or (from ne '' and to ne '') or (notBefore ne '' and notAfter ne '')">Missing expected date elements</sch:assert>
        </sch:rule>
        <sch:rule context="@utc">
            <sch:assert test=". castable as xs:dateTime">Invalid xs:dateTime value</sch:assert>
        </sch:rule>
    </sch:pattern>
</sch:schema>