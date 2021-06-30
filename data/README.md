# Data repo for "Development of an automatic tool for periodic surveillance of actuarial and demographic indicators"

This repository contains the data used for my final master project "Development of an automatic tool for periodic surveillance of actuarial and demographic indicators". This repository gets directly updated through the [Docker container](https://hub.docker.com/r/dreth/tfm_uc3m) prepared for the project.

The [main repo is dreth/tfm_uc3m](https://github.com/dreth/tfm_uc3m). There you can find more instructions, information, and the contents of this repository in the *data* folder, as a subtree. 

## 🗂️ Data sources

All data within this project is originally obtained from the [INE (Instituto Nacional de Estadística)](https://ine.es/) official data sources. 

The dataset for [deaths](https://github.com/dreth/tfm_uc3m/blob/main/data/death.csv) contained in the repository was sourced from [Eurostat's **demo_r_mwk2_05** dataset.](https://ec.europa.eu/eurostat/databrowser/view/demo_r_mwk2_05/default/table?lang=en). Which is originally sourced from INE's measurements.

The dataset for [population](https://github.com/dreth/tfm_uc3m/blob/main/data/pop.csv) was obtained from [INE's dataset ID: 9681](https://www.ine.es/jaxiT3/Tabla.htm?t=9681&L=0), titled: "*Resultados por comunidades autónomas / Población residente por fecha, sexo y edad*" (Original source in Spanish).

Both were obtained directly from each respective institution's API:

- [Eurostat's JSON and Unicode web services](https://ec.europa.eu/eurostat/web/json-and-unicode-web-services/getting-started/query-builder)
- [INE's JSON API service](https://www.ine.es/dyngs/DataLab/manual.html?cid=45)