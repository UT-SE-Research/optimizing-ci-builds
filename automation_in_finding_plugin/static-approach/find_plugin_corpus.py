import xml.etree.ElementTree as ET
from sklearn.feature_extraction.text import TfidfVectorizer
import sys
from sklearn.metrics.pairwise import cosine_similarity
import numpy as np
import json
from nltk.tokenize import word_tokenize
from nltk.stem import PorterStemmer
from nltk.tokenize import regexp_tokenize
import csv
from bs4 import BeautifulSoup

pomFile=sys.argv[1]
unnecessary_directory=sys.argv[2]
result_file=sys.argv[4]
stemmer = PorterStemmer()

# Get the root element of the XML file
# Read the content of the XML file
with open(pomFile, 'r') as file:
    xml_content = file.read()

key_list=[]
key_count=0
plugin_corpora_dict = {}
stop_word=["maven",""]
soup = BeautifulSoup(xml_content, 'xml')
plugins = soup.find_all('plugin')
for plugin in plugins:
    #group_id = plugin.find('groupId').text
    group_id_element = plugin.find('groupId')
    group_id = group_id_element.text if group_id_element else ""
    artifact_id = plugin.find('artifactId').text
    version = plugin.find('version').text
    print(f"GroupId: {group_id}, ArtifactId: {artifact_id}, Version: {version}")
    if group_id != "":
        key=group_id+'#'+artifact_id
    else:
        key=artifact_id
    key_list.append(key)
    key_count +=1
target_element = None
plugin_corpora_dict["empty"]=[]

with open('Unused_dir_And_all_tried_plugins.csv', 'a', newline='') as file:
    writer = csv.writer(file)
    writer.writerow(["Proj_name","Workflow","Java-Version","MVN-command","Uniq-ID","Unused-Dir-Name", "Plugin-That-Are-Used-For-Tf-IDF","Plugin-Count"])  # Write header
    writer.writerow([sys.argv[3],unnecessary_directory,key_list,key_count])

unnecessary_list_corpora=unnecessary_directory.split("/")
vectorizer = TfidfVectorizer()

#result_plugin="Result_with_only_plugin_name.csv"
#result_plugin_arr=[]
non_zero_matched_plugin_with_unused_dict={}
count=0
for plugin in key_list:
    if len(plugin) >=1 and len(unnecessary_list_corpora) >=1:
        #tfidf_list1 = vectorizer.transform(unnecessary_list_corpora)
        vectorizer.fit(unnecessary_list_corpora + [plugin])
        tfidf_list1 = vectorizer.transform(unnecessary_list_corpora)
        tfidf_list2 = vectorizer.transform([plugin])
        cosine_sim = cosine_similarity(tfidf_list1, tfidf_list2)
        local_max_sim = np.max(cosine_sim)
        print('****plugin=',plugin,',unnecessary_directory=', unnecessary_directory ,',score=',local_max_sim)
        if local_max_sim > 0.0:
            count +=1
            #result_plugin_arr.append(plugin+':'+str(round(local_max_sim,3)))
            non_zero_matched_plugin_with_unused_dict[plugin]=round(local_max_sim,3)

sorted_dict=dict(sorted(non_zero_matched_plugin_with_unused_dict.items(), key=lambda x:x[1],reverse=True))
with open(result_file, 'a') as file:
    #f.write(sorted_dir)
    file.write(str(sorted_dict))
    file.write(','+str(count))

'''with open(result_plugin, 'a', newline='') as file:
    writer = csv.writer(file)
    writer.writerow(["Proj_name","Workflow","Unused-Dir-Name", "Plugin-Name"])  # Write header
    writer.writerow([sys.argv[3],sys.argv[4],unnecessary_directory, result_plugin_arr])

with open(result_file, 'a') as file:
    file.write(str(result_plugin_arr))'''

###SIMILARITY SCORE CALCULATE Based off of the full plugin info
'''non_zero_matched_plugin_with_unused_dict={}
plugin=""
count=0

for key, plugin in plugin_corpora_dict.items():
    #print('****Value='+str(value))
    vectorizer.fit(unnecessary_list_corpora + plugin)
    # Transform the lists into TF-IDF vectors
    #print(len(value))
    if len(plugin) >=1 and len(unnecessary_list_corpora) :
        count +=1
        tfidf_list1 = vectorizer.transform(unnecessary_list_corpora)
        tfidf_list2 = vectorizer.transform(plugin)
        cosine_sim = cosine_similarity(tfidf_list1, tfidf_list2)
        #print(cosine_sim)
        local_max_sim = np.max(cosine_sim)
        #if local_max_sim > 0.0:
        non_zero_matched_plugin_with_unused_dict[key]=round(local_max_sim,3)

#sorted_dict=dict(sorted(non_zero_matched_plugin_with_unused_dict.items(), key=lambda x:x[1],reverse=True))
sorted_dict=dict(non_zero_matched_plugin_with_unused_dict.items(), key=lambda x:x[1],reverse=True)
with open(result_file, 'a') as file:
    #f.write(sorted_dir)
    file.write(str(sorted_dict))
    file.write(str(count))'''
    #json.dump(sorted_dict, file)'''
#print(sorted_dict)
