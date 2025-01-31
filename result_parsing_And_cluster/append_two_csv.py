import csv 
import pandas as pd
import sys 
import numpy as np
# Define the file paths
#input_file = "test_name.csv"
input_file=sys.argv[1]
output_file = sys.argv[2]
new_df= pd.read_csv(input_file)
existing_df= pd.read_csv(output_file)
existing_df['java_version']=existing_df['java_version'].fillna(0).astype(np.uint8)

merged_df = pd.merge(existing_df, new_df[['unused_csv_file', 'unused_dirs']], on='unused_csv_file')
merged_df.to_csv('Unused_clusters_info.csv', index=False)

