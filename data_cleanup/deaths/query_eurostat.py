import requests
import json
import pandas as pd

url = 'http://ec.europa.eu/eurostat/wdds/rest/data/v2.1/json/en/demo_r_mwk2_05?sinceTimePeriod=2010W01&precision=1&sex=F&geo=ES11&geo=ES12&geo=ES13&geo=ES21&geo=ES22&geo=ES23&geo=ES24&geo=ES3&geo=ES41&geo=ES42&geo=ES43&geo=ES51&geo=ES52&geo=ES53&geo=ES61&geo=ES62&geo=ES63&geo=ES64&geo=ES7&unit=NR&age=Y10-14'

response = json.loads(requests.get(url).text)

# generating metadata col
# region_codes = response['dimension']['geo']['category']['label'].keys()
# age_group = response['dimension']['age']['category']['label'].keys()[0]
# sex_group = response['dimension']['age']['category']['label'].keys()[0]

# for region_code in :



# df = {
#     'metadata':,
#     'time':list(response['dimension']['time']['category']['index'].keys())
# }