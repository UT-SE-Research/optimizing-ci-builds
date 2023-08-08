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

pomFile=sys.argv[1]
unnecessary_directory=sys.argv[2]
result_file=sys.argv[4]
stemmer = PorterStemmer()
# Load the XML file
tree = ET.parse(pomFile)

# Get the root element of the XML file
root = tree.getroot()
key_list=[]
plugin_corpora_dict = {}
stop_word=["maven",""]
# if the element is found, traverse its children and descendants
# 1. ***************Will look for effective pom, and then [[ DONE  ]] *********
#2. output will be artifactId and groupId artifactId
target_element = None
for elem in root.iter():
    if elem.tag.endswith('}' + 'build'):
        target_element = elem
        break
if target_element is not None:
    for child1 in target_element.iter():
        if child1.tag.endswith('}' + 'plugins'):
            for child2 in child1.iter():
                if child2.tag.endswith('}' + 'plugin'):
                    key=""
                    level_count=0
                    corpora_list=[]
                    #plugin_count +=1
                    for child3 in child2.iter():
                        #print('child3.tag='+child3.tag.split("}")[1])
                        level_count +=1
                        if level_count <= 3:
                            #print(child3.tag)
                            if child3.tag.split("}")[1] == "artifactId" or child3.tag.split("}")[1] == "groupId":
                                if key == "":
                                     key=child3.text
                                     #print('ID when key is empty,key=',key)
                                else:
                                     key = key+"#"+child3.text
                                     #print('merging groupId and artifactId,key=',key)

                        if child3.text is not None and child3.text.strip()!= "":
                            # tokenize the file contents
                            #tokens = regexp_tokenize(child3.text, pattern='\w+[-]\w+|\w+')
                            #tokens = word_tokenize(separated_by_hypen)
                            #stemmed_tokens = [stemmer.stem(token) for token in tokens]
                            corpora_list.append(child3.text)               
                    #key="plugin"+str(plugin_count)
                    plugin_corpora_dict[key]=corpora_list
                    #print(key + ",corpora_list"+ str(corpora_list))
                    #print("keys="+key)
                    key_list.append(key)


                    #print(corpora_list)
plugin_corpora_dict["empty"]=[]

with open('Unused_dir_And_all_tried_plugins.csv', 'a', newline='') as file:
    writer = csv.writer(file)
    writer.writerow(["Proj_name","Workflow","Java-Version","MVN-command","Uniq-ID","Unused-Dir-Name", "Plugin-That-Are-Used-For-Tf-IDF"])  # Write header
    writer.writerow([sys.argv[3],unnecessary_directory, key_list])

'''unnecessary_list_corpora=unnecessary_directory.split("/")
vectorizer = TfidfVectorizer()

result_plugin="Result_with_only_plugin_name.csv"
result_plugin_arr=[]
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
            result_plugin_arr.append(plugin+':'+str(round(local_max_sim,3)))

with open(result_plugin, 'a', newline='') as file:
    writer = csv.writer(file)
    writer.writerow(["Proj_name","Workflow","Unused-Dir-Name", "Plugin-Name"])  # Write header
    writer.writerow([sys.argv[3],sys.argv[4],unnecessary_directory, result_plugin_arr])

with open(result_file, 'a') as file:
    file.write(str(result_plugin_arr))'''

###SIMILARITY SCORE CALCULATE Based off of the full plugin info
non_zero_matched_plugin_with_unused_dict={}
plugin=""
for key, plugin in plugin_corpora_dict.items():
    #print('****Value='+str(value))
    vectorizer.fit(unnecessary_list_corpora + plugin)
    # Transform the lists into TF-IDF vectors
    #print(len(value))
    if len(plugin) >=1 and len(unnecessary_list_corpora) :
        tfidf_list1 = vectorizer.transform(unnecessary_list_corpora)
        tfidf_list2 = vectorizer.transform(plugin)
        cosine_sim = cosine_similarity(tfidf_list1, tfidf_list2)
        #print(cosine_sim)
        local_max_sim = np.max(cosine_sim)
        if local_max_sim > 0.0:
            non_zero_matched_plugin_with_unused_dict[key]=round(local_max_sim,3)
sorted_dict=dict(sorted(non_zero_matched_plugin_with_unused_dict.items(), key=lambda x:x[1],reverse=True))
with open(result_file, 'a') as file:
    #f.write(sorted_dir)
    file.write(str(sorted_dict))
    #json.dump(sorted_dict, file)'''
#print(sorted_dict)
