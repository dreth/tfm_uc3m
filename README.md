# Development of an automatic tool for periodic surveillance of actuarial and demographic indicators

This is the repository for my final master project at UC3M titled "Development of an automatic tool for periodic surveillance of actuarial and demographic indicators".

The repository name comes from the commonly used acronym "tfm" meaning "*Trabajo de Fin de Master*" (final master project in Spanish) and where I coursed the master, [UC3M](https://uc3m.es).
## Tutors

- [María Luz Durbán Reguera](https://researchportal.uc3m.es/display/inv18373)
- [Bernardo D'Auria](https://portal.uc3m.es/portal/page/portal/dpto_estadistica/home/members/bernardo_d_auria)

## Sources

### Data sources

All data within this project is originally obtained from the [INE (Instituto Nacional de Estadística)](https://ine.es/) official data sources. 

The dataset for [deaths](https://github.com/dreth/tfm_uc3m/blob/main/data/death.csv) contained in the repository was sourced from [Eurostat's **demo_r_mwk2_05** dataset.](https://ec.europa.eu/eurostat/databrowser/view/demo_r_mwk2_05/default/table?lang=en). Which is originally sourced from INE's measurements.

The dataset for [population](https://github.com/dreth/tfm_uc3m/blob/main/data/pop.csv) was obtained from [INE's dataset ID: 9681](https://www.ine.es/jaxiT3/Tabla.htm?t=9681&L=0), titled: "*Resultados por comunidades autónomas / Población residente por fecha, sexo y edad*" (Original source in Spanish).

Both were obtained directly from each respective institution's API:

- [Eurostat's JSON and Unicode web services](https://ec.europa.eu/eurostat/web/json-and-unicode-web-services/getting-started/query-builder)
- [INE's JSON API service](https://www.ine.es/dyngs/DataLab/manual.html?cid=45)

### Map polygon layer

The map polygon layer was obtained from [ArcGIS' website](https://www.arcgis.com/home/item.html?id=e75892d1a49646d8a29705ac6680f981), it was produced by the [IGN (Instituto Geográfico Nacional de España)](https://www.ign.es).

### Base docker image

The docker image used as base was created by [rocker-org](https://github.com/rocker-org). The docker hub tag is **rocker/shiny-verse**, and it's a base image that includes *shiny* and *tidyverse*, I built mine on top of this one.

You can find the base image source in the following [repository folder](https://github.com/rocker-org/shiny/tree/master/shiny-verse). Or you can also find it in Docker hub in the following [repository](https://hub.docker.com/r/rocker/shiny-verse).

## Running the application

### Docker

I have created a docker container for the application, this way we avoid any requirements needing to be installed in your OS. This is the recommended approach to run it.

You can download docker [here](https://www.docker.com/products/docker-desktop) if you don't have it installed yet, it is the only requirement to run the application.

#### Docker hub

Given docker is installed, the app can be launched by running the following lines of code. This will pull the container from Docker hub and run the application:

```bash
docker run -p 3838:3838/tcp dreth/tfm_uc3m:latest
```

Then navigate to [**http://0.0.0.0:3838/**](http://0.0.0.0:3838/) on your web browser.

It might take a bit to download entirely at first as the image is somewhat large, however, once downloaded, the app can be launched and it will always pull the newest version from github. 

The data can also be updated, however, database updates performed within the app will only be local and won't update the data included within the repo itself. This might change for future updates, but the only limitation from this might be that if the data within the repo is outdated, it will have to be updated directly by whoever has write access to this repository, unless a local update is performed, which the app can perform in the *update database* tab.

#### Building

In case you prefer to build the container yourself, the repository contains a Dockerfile from which it can be built and run as follows:

```bash
docker build https://github.com/dreth/tfm_uc3m.git#main:docker -t dreth:tfm_uc3m
docker run -p 3838:3838/tcp dreth:tfm_uc3m
```

This approach will always guarantee you're pulling the latest version of the container, as I might take slightly longer to push changes to the container to docker hub unless they're significant. However, since the container always pulls the latest version of the app from github, any version of it will run the latest version of the app after pulled.

That said, changes to the container won't happen very often.

You might require administrative privileges to build docker containers. If on sh/zsh/bash, you can use ```sudo```.

---

### Running directly on R

It is recommended to use the docker approach described above, nevertheless, if you want to do so otherwise, it is possible to run the full-featured application as follows:

#### R requirements

To be able to use every feature in the app, a series of requirements must be met, all the R libraries used can be found in the first few lines of the *global.R* file, located [here](https://github.com/dreth/tfm_uc3m/blob/main/dashboard/global.R). Which can be installed as follows:

```R
install.packages(c('shiny','shinydashboard','shinyjs','tidyverse','shinythemes','pracma','dplyr','ggplot2','stringr','MASS','plotly','leaflet','rgdal','RColorBrewer','zoo','RcppRoll'))
```

#### Python requirements

Also, in order to be able to update the database, Python 3.8 must be installed along with the following libraries:

```Python
pip3 install requests json numpy pandas datetime copy
```

As shown in the *functions.py* file, located [here](https://github.com/dreth/tfm_uc3m/blob/main/api/functions.py).

#### Bash scripts

Your system should also be able to run *bash* scripts, therefore it is recommended that you use a *linux* or *macOS* system.

Once such requirements have been met, the app can be ran as follows:

```R
runGitHub(repo='tfm_uc3m', username='dreth', ref='main', subdir='dashboard')
```
