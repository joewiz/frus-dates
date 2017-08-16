# frus-dates

A proof of concept for FRUS chronological search and sort functionality. 

## Data sources

- [_Foreign Relations of the United States_](https://history.state.gov/historicaldocuments) (see raw data at the [HistoryAtState/frus](https://github.com/HistoryAtState) GitHub repository)

## Status

Date reconciliation still in process.

## Dependencies

- The data in `data` is XML and so has no dependencies
- But the application runs in [eXist-db](http://exist-db.org). Requires 3.x.
- Building the installable package requires Apache Ant

## Installation

- Check out the repository
- Run `ant`
- Upload build/frus-dates-0.1.xar to eXist-db's Dashboard > Package Manager
- Open http://localhost:8080/exist/apps/frus-dates
- Enjoy!
