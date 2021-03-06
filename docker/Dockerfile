FROM rocker/shiny-verse:latest

# Get required packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    python3.8 \
    python3-pip \
    python3-setuptools \
    python3-dev \
    libudunits2-dev \
    libgdal-dev \
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
RUN R -e "install.packages('leaflet')"
RUN R -e "install.packages('rgdal')"
RUN R -e "install.packages('zoo')"
RUN R -e "install.packages('devtools')"
RUN R -e "require(devtools); install.packages('Rcpp', version='1.0.7')"
RUN R -e "install.packages('RcppRoll')"

# cloning the project repos
RUN git clone https://github.com/dreth/tfm_uc3m.git
RUN git clone https://github.com/dreth/tfm_uc3m_data.git

# select port
EXPOSE 3838/tcp

# running app from repo
CMD cd ./tfm_uc3m && git pull && cd ../tfm_uc3m_data && git pull && cp -r ./* ../tfm_uc3m/data && cd ../tfm_uc3m/dashboard && R -e "shiny::runApp(port = 3838, host = '0.0.0.0', launch.browser=FALSE)"