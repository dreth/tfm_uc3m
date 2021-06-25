# Development of an automatic tool for periodic surveillance of actuarial and demographic indicators

This is the repository for my final master project at UC3M titled "Development of an automatic tool for periodic surveillance of actuarial and demographic indicators".

The repository name comes from the commonly used acronym "tfm" meaning "*Trabajo de Fin de Master*" (final master project in Spanish) and where I coursed the master, [UC3M](https://uc3m.es).
## 👩‍💼 Tutors

- [María Luz Durbán Reguera](https://researchportal.uc3m.es/display/inv18373)
- [Bernardo D'Auria](https://portal.uc3m.es/portal/page/portal/dpto_estadistica/home/members/bernardo_d_auria)

## 🗝 Sources

### 🗂️ Data sources

All data within this project is originally obtained from the [INE (Instituto Nacional de Estadística)](https://ine.es/) official data sources. 

The dataset for [deaths](https://github.com/dreth/tfm_uc3m/blob/main/data/death.csv) contained in the repository was sourced from [Eurostat's **demo_r_mwk2_05** dataset.](https://ec.europa.eu/eurostat/databrowser/view/demo_r_mwk2_05/default/table?lang=en). Which is originally sourced from INE's measurements.

The dataset for [population](https://github.com/dreth/tfm_uc3m/blob/main/data/pop.csv) was obtained from [INE's dataset ID: 9681](https://www.ine.es/jaxiT3/Tabla.htm?t=9681&L=0), titled: "*Resultados por comunidades autónomas / Población residente por fecha, sexo y edad*" (Original source in Spanish).

Both were obtained directly from each respective institution's API:

- [Eurostat's JSON and Unicode web services](https://ec.europa.eu/eurostat/web/json-and-unicode-web-services/getting-started/query-builder)
- [INE's JSON API service](https://www.ine.es/dyngs/DataLab/manual.html?cid=45)

### 🗺️ Map polygon layer

The map polygon layer was obtained from [ArcGIS' website](https://www.arcgis.com/home/item.html?id=e75892d1a49646d8a29705ac6680f981), it was produced by the [IGN (Instituto Geográfico Nacional de España)](https://www.ign.es).

### 📦 Base docker image

The docker image used as base was created by [rocker-org](https://github.com/rocker-org). The docker hub tag is **rocker/shiny-verse**, and it's a base image that includes *shiny* and *tidyverse*, I built mine on top of this one.

You can find the base image source in the following [repository folder](https://github.com/rocker-org/shiny/tree/master/shiny-verse). Or you can also find it in Docker hub in the following [repository](https://hub.docker.com/r/rocker/shiny-verse).

## 🏃‍♀️ Running the application

### ⭐ Docker

I have created a docker container for the application, this way we avoid any requirements needing to be installed in your OS. This is the recommended approach to run it.

You can download docker [here](https://www.docker.com/products/docker-desktop) if you don't have it installed yet, it is the only requirement to run the application.

#### Docker hub

**All features** are available when using this method.

Given docker is installed, the app can be launched by running the following lines of code. This will pull the container from Docker hub and run the application:

```bash
docker run -it -p 3838:3838/tcp dreth/tfm_uc3m:latest
```

Then navigate to [**http://0.0.0.0:3838/**](http://0.0.0.0:3838/) on your web browser.

It might take a bit to download entirely at first as the image is somewhat large, however, once downloaded, the app can be launched and it will always pull the newest version from github. 

The data can also be updated, however, database updates performed within the app will only be local and won't update the data included within the repo itself. This might change for future updates, but the only limitation from this might be that if the data within the repo is outdated, it will have to be updated directly by whoever has write access to this repository, unless a local update is performed, which the app can perform in the *update database* tab.

#### Building

**All features except pushing data to the [data repo](https://github.com/dreth/tfm_uc3m_data)** are available using this method.

In case you prefer to build the container yourself, the repository contains a Dockerfile from which it can be built and run as follows:

```bash
docker build https://github.com/dreth/tfm_uc3m.git#main:docker -t dreth/tfm_uc3m
docker run -it -p 3838:3838/tcp dreth/tfm_uc3m
```

This always ensures you're using the latest version of the container, however, this approach will not allow you to push database changes to the [data folder's repository](https://github.com/dreth/tfm_uc3m_data), unlike using the container uploaded to docker hub, although you will still be able to update the data locally if you desire to do so.

---

### Running directly on R

**All features except pushing data to the [data repo](https://github.com/dreth/tfm_uc3m_data)** are available using this method, although there are significantly more requirements to use it.

If on windows, you will not be able to update the database locally either unless you manually clone the repo and run the [query.py](https://github.com/dreth/tfm_uc3m/blob/main/api/query.py) python script.

It is recommended to pull the docker hub container as described above, nevertheless, if you still want to do so through directly through R, it is possible to run the application as described below.

#### R requirements

To be able to use every feature in the app, a series of requirements must be met, all the R libraries used can be found in the first few lines of the *global.R* file, located [here](https://github.com/dreth/tfm_uc3m/blob/main/dashboard/global.R). Which can be installed as follows:

```R
install.packages(c('shiny','shinydashboard','shinyjs','tidyverse','shinythemes','pracma','dplyr','ggplot2','stringr','MASS','plotly','leaflet','rgdal','RColorBrewer','zoo','RcppRoll'))
```

#### Python requirements

Also, in order to be able to update the database, Python 3.8 must be installed along with several libraries which you can install as follows through *pip*:

```Python
pip3 install requests json numpy pandas datetime copy
```

If you have the anaconda distribution installed as your python interpreter, most if not all of these requirements are installed out of the box, otherwise you can install them through *conda* as follows:

```Python
conda install requests json numpy pandas datetime copy
```

#### Bash scripts

Your system should also be able to run shell scripts, therefore it is recommended that you use a *linux* or *macOS* system or the *WSL* on *Windows*.

#### Launch the app directly on R

Once such requirements have been met, the app can be ran through an R interactive console as follows:

```R
runGitHub(repo='tfm_uc3m', username='dreth', ref='main', subdir='dashboard')
```

If on a shell console, you can also run the app as follows if the R binary is on your PATH:

```Shell
R -e "shiny::runGitHub(repo='tfm_uc3m', username='dreth', ref='main', subdir='dashboard')"
```

## Closing the application

### What should always work

In order to close the application, if ran through a console using either the docker CLI approach or directly through an R interactive console, you can always kill the application using *Ctrl+C*.

### Docker

Using *Ctrl+C* should always work and has always worked in my testing, however, when running the docker container, if the container's execution is not halted by using *Ctrl+C* you can do the following to kill the container:

```Shell
docker ps
```

Check the container ID, copy it either using *Ctrl+Shift+C* or right clicking the console's text and copying directly using the context menu, and running the following command:

```Shell
docker kill <Container ID>
```

And replacing ```<Container ID>``` with the copied container ID from running ```docker ps```.

If the container ID and tag do not show up when running ```docker ps```, the container's execution was successfully halted.