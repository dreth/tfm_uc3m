# Development of an automatic tool for periodic surveillance of actuarial and demographic indicators

Repository for my final master project at UC3M titled "Development of an automatic tool for periodic surveillance of actuarial and demographic indicators"

## My tutors for the project

- [María Luz Durbán Reguera](https://researchportal.uc3m.es/display/inv18373)
- [Bernardo D'Auria](https://portal.uc3m.es/portal/page/portal/dpto_estadistica/home/members/bernardo_d_auria)

## Running the application

### Docker

I have created a docker container for the application, this way we avoid any requirements needing to be installed in your OS. This is the recommended approach to run it, as the application has important requirements to run.

#### Docker hub

The container will be uploaded to Docker hub soon, alternatively, you can build the container, as explained in the next section.

#### Building

The repository contains a Dockerfile which can be built and run as follows given [docker](https://www.docker.com/products/docker-desktop) is installed:

```bash
docker build https://github.com/dreth/tfm_uc3m.git#main:docker -t tfm_app
docker run -p 3838:3838/tcp tfm_app
```

This approach is OS-agnostic and allows you to run the application without installing any requirements other than *docker* itself.

You might require administrative privileges to build docker containers. If on sh/zsh/bash, you can use ```sudo```.

---

### Running directly on R

It is recommended to use the docker approach described above, however, if you want to do so otherwise, it is possible to run the full-featured application as follows:

#### R requirements

To be able to use every feature in the app, a series of requirements must be met, all the R libraries used can be found in the first few lines of the *global.R* file, located [here](https://github.com/dreth/tfm_uc3m/blob/main/dashboard/global.R). And are the following:

```R
require(shiny)
require(shinydashboard)
require(shinyjs)
require(tidyverse)
require(shinythemes)
require(pracma)
require(dplyr)
require(ggplot2)
require(stringr)
require(MASS)
require(plotly)
```

#### Python requirements

Also, in order to be able to update the database, Python 3.8 must be installed along with the following libraries:

```Python
import requests
import json
import pandas
import datetime
import numpy
import copy
```

As shown in the *query.py* file, located [here](https://github.com/dreth/tfm_uc3m/blob/main/api/query.py).

#### Bash scripts

Your system should also be able to run *bash* scripts, therefore it is recommended that you use a *linux* or *macOS* system.

Once such requirements have been met, the app can be ran as follows:

```R
runGitHub(repo='tfm_uc3m', username='dreth', ref='main', subdir='dashboard')
```