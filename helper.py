# help to extract key value from papi high level report
import subprocess

import json
import pandas as pd
import os
from pandas import json_normalize

path = './output'  # dir of saving papi out result
if not os.path.exists(path):
    os.makedirs(path)

dict_data = {}

def read_papi_rec(path):
    file_name = os.listdir(path)[0]
    file_path = os.path.join(path, file_name)

    with open(str(file_path)) as json_file:
        rec = json.load(json_file)
    threads_num =len(rec['threads'])
    PAPI_SP_OPS = 0
    for i in range(threads_num):
        PAPI_SP_OPS += int(rec['threads'][i]['regions'][0]['cpu_multicore']['PAPI_SP_OPS'])
    df = json_normalize(rec['threads'][0]['regions'])
    df_0 = df.iloc[0]
    print(PAPI_SP_OPS)
    return df_0

for i in range(3):
        subprocess.call("./tiling_alpha", shell=True)  # testing purpose
        dict_key = 'iter' + str(i)  # define key as needed
        df_0 = read_papi_rec(path)
        dict_data[dict_key] = df_0

df_saved = pd.DataFrame.from_dict(dict_data, orient='index')
df_saved.to_csv('papi_data.csv')