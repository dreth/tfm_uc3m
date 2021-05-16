FROM rocker/shiny-verse:latest

# Get required packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    python3.8 \
    python3-pip \
    python3-setuptools \
    python3-dev \
    libssl-dev \
    git

# installing python libraries
RUN pip3 install pandas
RUN pip3 install numpy
RUN pip3 install datetime
RUN pip3 install requests

# installing r libraries
RUN R -e "install.packages('shinydashboard')"
RUN R -e "install.packages('shinyjs')"
RUN R -e "install.packages('shinythemes')"
RUN R -e "install.packages('pracma')"
RUN R -e "install.packages('ggplot2')"
RUN R -e "install.packages('stringr')"
RUN R -e "install.packages('MASS')"
RUN R -e "install.packages('plotly')"

# select port
EXPOSE 3838/tcp

# running app from repo
CMD ["R", "-e", "shiny::runGitHub(repo='tfm_uc3m', username='dreth', ref='main', subdir='dashboard', host = '0.0.0.0', port = 3838, launch.browser=FALSE)"]