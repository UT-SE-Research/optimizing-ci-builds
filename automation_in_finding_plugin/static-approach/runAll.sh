#!/bin/bash
if [[ $1 == "" ]]; then
    echo "give the csv name (e.g., ../../result_parsing_And_cluster/Unused_clusters_info.csv)"
    exit
fi

currentDir=$(pwd)
header=true
result="$currentDir/TF_IDF_Result_without_plugin_dependency.csv"
#result="$currentDir/Result_with_all_plugin_dependency.csv"
while read line
do 
    #if [ "$header" = false ]; then 
    input_upto_colum_five=$(echo $line | cut -d',' -f1-5)
    echo $input_upto_colum_five
    proj_name=$(echo $line | cut -d',' -f1)
    workflow_file=$(echo $line | cut -d',' -f2)
    java_version=$(echo $line | cut -d',' -f3)
    mvn_command=$(echo $line | cut -d',' -f4)
    unused_csv_file=$(echo $line | cut -d',' -f5)
    unused_dirs=$(echo $line | cut -d',' -f6)
    git clone "git@github.com:optimizing-ci-builds/$proj_name" "../projects/$proj_name"
    ###############FIND EFFECTIVE POM#################
    if [[ $proj_name == "open-location-code" ]]; then
        cd "../projects/$proj_name/java"
    else
        cd "../projects/$proj_name"
    fi
    #java_version=$(grep -i "java-version" $workflow_file  | head -1 | cut -d':' -f2 )
    #java_version="${java_version//\'/}"
    #echo $java_version

    if [[ "$java_version" == *"17"* ]]; then
        echo "JAVA -17"
        export JAVA_HOME=/usr/lib/jvm/java-1.17.0-openjdk-amd64/
    elif [[ "$java_version" == *"11"* ]]; then
        echo "JAVA -11"
        export JAVA_HOME=/usr/lib/jvm/java-1.11.0-openjdk-amd64/
    elif [[ "$java_version" == *"8"* ]]; then
        export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64/
        echo "JAVA -8"
        echo $JAVA_HOME
    fi
    pom_exists=$(find .  -maxdepth 1 -name "pom.xml" | wc -l) #This is needed if the project is not maven based
    if [[ $pom_exists -eq 0 ]]; then
        echo "$proj_name,$workflow_file,$java_version,$mvn_command,$unused_csv_file-[NOT-MAVEN],${unnecessary_dir}" >> "$result"
        continue
    fi
    mvn org.apache.maven.plugins:maven-help-plugin:3.4.0:effective-pom -Doutput=effective-pom.xml
     range_build_plugins=($(awk '/<build>/,/<\/build>/ {
    if(/<plugins>/) {
        if(!pMgmt) {start=NR}
    }
    if(/<\/plugins>/) {
        if(!pMgmt) {print start; print NR; exit}
    }
    if(/<pluginManagement>/) {
        pMgmt=1
    }
    if(/<\/pluginManagement>/) {
        pMgmt=0
    }
}' effective-pom.xml)) #this one is ignoring the plugins if it belongs to pluginManagement

    Start_range="${range_build_plugins[0]}"
    end_range="${range_build_plugins[1]}"
    #sed -n "$Start_range,${end_range}p" effective-pom.xml | awk -v adj=$Start_range '{printf("%-5d%s\n", NR-1+adj, $0)}' > tmp.xml
    sed -n "$Start_range,${end_range}p" effective-pom.xml | awk '{print}' > tmp.xml

    if [[ -f tmp.xml ]]; then
        cd $currentDir
        #Find each unused dir one by one
        tildeCount=$(echo ${unused_dirs} | tr -cd '~' | wc -c)
        echo ${unused_dirs} ${tildeCount}
        for (( i=1; i<=${tildeCount}; i++))
        do
            unnecessary_dir=$(echo "$unused_dirs" | cut -d'~' -f$i)
            semicolon_found_indicates_file=$(echo  $unnecessary_dir | grep ";" | wc -l)
            #echo "Should be greater than 1=$semicolon_found_indicates_file"

            if [[ $semicolon_found_indicates_file -eq 0 ]]; then
                #echo "UNU $unnecessary_dir"
                echo -n "$proj_name,$workflow_file,$java_version,$mvn_command,${unused_csv_file},${unnecessary_dir}," >> "$result"
                
                if [[ $proj_name == "open-location-code" ]]; then
                    python3 find_plugin_corpus.py "../projects/$proj_name/java/tmp.xml" ${unnecessary_dir} "$input_upto_colum_five" $result
                else
                    python3 find_plugin_corpus.py "../projects/$proj_name/tmp.xml" ${unnecessary_dir} "$input_upto_colum_five" $result
                fi
                #echo "SHANTO*** ${unnecessary_dir}"
                echo "" >> "$result"
            fi
        done
    fi
    cd $currentDir
    rm -rf "../projects/$proj_name/"
    #fi
    #header=false
done < $1

