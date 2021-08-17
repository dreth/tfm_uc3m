# Database information and update tab

## Description

The database information and update section contains information with respect to the different databases. This information is updated every time the app is newly launched. The information shown is the following:

- Last time the database was updated by any user of the application.
- Diagnostic information about the **deaths** database:
  + Latest date for which there is obtainable data from Eurostat.
  + Latest date for which the data is currently updated in the container (or computer) where the app is running.
  + Earliest date since when the data is provisional.
  + The original database ID from Eurostat.
- Diagnostic information about the **population** database:
  + Latest date for which there is obtainable data from INE.
  + The original database ID from INE.

## Controls

The only control available is the *update database* button, which allows for the database to be updated. 

If the app is being run using the *docker* container, then updating the database from the app will upload any newly updated data to the [data repository](https://github.com/dreth/tfm_uc3m_data) if there is data available.