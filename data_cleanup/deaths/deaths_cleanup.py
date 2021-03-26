import pandas as pd
import os

def deaths_cleanup(dataset, metadata_colname):
    # %% Provisional variable for the output of the function
    output = dataset.copy()

    # %% Cleaning up provisional data number indicator (p)
    for col in output.columns[1:]:
        output[col] = output[col].apply(lambda x: int(str(x).replace('p', '')))

    # %% Melting the dataframe for easier management
    output = pd.melt(output, id_vars=[metadata_colname], value_vars=[
                     x for x in output.columns if x != metadata_colname])

    # rename variables
    output = output.rename(columns={
        metadata_colname: 'metadata',
        'variable': 'year_week',
        'value': 'deaths'
    })

    # %% Obtaining sex and age group to create new col with it
    output['ccaa'] = [x.split(',')[-1] for x in output.metadata]
    output['sex'] = [x.split(',')[2] for x in output.metadata]
    output['age'] = [x.split(',')[1] for x in output.metadata]

    # %% Return the resulting dataframe
    return output


def deaths_append_datasets(path, read_csv_options):
    # %% traverse file tree and append to file list
    # all the datasets
    files = []
    for root, d_names, f_names in os.walk(path):
        for f in f_names:
            files.append(os.path.join(root, f))

    # %% append all dataframes to a list
    dataframes = []
    for p in files:
        dataframes.append(pd.read_csv(p, **read_csv_options))

    # %% append all dataframes together
    output = pd.concat(dataframes)

    # %% return the resulting dataframe
    return output


# running the function for the deaths folder
data = deaths_cleanup(deaths_append_datasets(
    '../../data/deaths', {'sep': '\t'}), 'freq,age,sex,unit,geo\TIME_PERIOD')

# removing the metadata column to save space
data = data.drop('metadata', axis=1)

# saving as csv
data.to_csv('deaths.csv')