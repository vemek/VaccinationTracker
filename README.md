# VaccinationTracker

<img width="567" alt="Screenshot 2021-03-01 at 19 59 51" src="https://user-images.githubusercontent.com/82409/109554134-c101c300-7acb-11eb-9a20-a4461fa9204e.png">

Status bar app for macOS that displays per-country progress of the COVID-19 vaccination rollout. Numbers pulled from [Our World in Data's COVID-19 repository](https://github.com/owid/covid-19-data/tree/master/public/data).

The app will show the projected percentage of the population of a given country who has received at least one dose of any vaccine. This is based on the last known figure reported for that country, combined with a smoothed average number of vaccinations administered daily to provide an estimate on the up-to-date percentage. The context menu for the app lets you change which country is reported, as well as shows you some more figures (both projected and official).
The estimate is updated every 5 minutes based on the most recent projection. The data is refreshed from the OWID repo every hour.

## Installation
Grab [the latest version from the Releases page](https://github.com/vemek/VaccinationTracker/releases). Open it, then drag the app into your Applications folder.
