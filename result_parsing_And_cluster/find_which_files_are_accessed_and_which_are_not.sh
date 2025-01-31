#!/bin/bash
if [[ $1 == "" ]]; then
    echo "give csv $1 (workflow_dir.csv)"
    exit
fi

currentDir=$(pwd)
Output="Output"
if [[ -f "projects_name_per_yaml.csv" ]]; then
    rm "projects_name_per_yaml.csv"
fi

output_proj_name=$2
workflow_name=$(echo $1 | rev |cut -d'/' -f2-3| rev | sed 's/\//-/g' )
echo "workflow name= ${workflow_name}"
proj_with_workflow="${output_proj_name}#$workflow_name"

echo $proj_with_workflow >> "projects_name_per_yaml.csv"

if [ -f "$currentDir/$Output/$proj_with_workflow-never-accessed" ]; then
    rm "$currentDir/$Output/$proj_with_workflow-never-accessed"
fi

if [ -f "$currentDir/$Output/$proj_with_workflow-accessed" ]; then
    rm "$currentDir/$Output/$proj_with_workflow-accessed"
fi
dir_arr=($(cd "$1" && printf -- '%s\n' */))
echo "Line 39 ${dir_arr}" 
cd "$1"
never_accessed_file_name_array=("cm_a.csv" "c_m_a.csv" "c_m__a.csv" "cm__a.csv"  "_cm_a.csv"  "_cm__a.csv.csv"  "_c_m_a.csv" "_c_m__a.csv" )
#accessed_file_name_array=("cma.csv" "c_ma.csv" "_cma.csv"  "_c_ma.csv"  )

if [[ ! -d "$currentDir/$Output" ]]; then
    mkdir "$currentDir/$Output"
fi

for i in "${dir_arr[@]}"
do

    echo "==========$i ========== $(pwd)"
    if [[ "$i" =~ .*"checkout".* ]]; then
        #echo "checkout found"
        continue
    elif [[ "$i" =~ .*"setup".* ]]; then
       #echo "setup found"
       continue
    else
        for j in "${never_accessed_file_name_array[@]}"
        do
            #echo $i$j
            if [ -f $i$j ]; then
                #echo "Found $i$j"
                cat "$i$j" >> "$currentDir/$Output/$proj_with_workflow-never-accessed"
            else 
                echo "Not Found"
            fi
        done
    fi
done

### Process useful.csv

cd $currentDir
if [[ -f  "$currentDir/$Output/$proj_with_workflow-useful" ]]; then  
    rm "$currentDir/$Output/$proj_with_workflow-useful"
fi
row_count=1
while read line
do
    if [[ ${row_count} -gt 1 ]]; then
        file_name=$(echo $line | cut -d',' -f2)
        echo $file_name >>  "$currentDir/$Output/$proj_with_workflow-useful" 
    fi
    row_count=$((row_count+1))
done < "$1/../useful.csv"

cat "$currentDir/$Output/$proj_with_workflow-never-accessed" | cut -d',' -f2 > "$currentDir/tmp1"
cat "$currentDir/tmp1" | sort | uniq > "$currentDir/tmp"
cp "$currentDir/tmp" "$currentDir/$Output/$proj_with_workflow-never-accessed" 
rm "$currentDir/tmp1"
rm "$currentDir/tmp"

if [[ -f "$currentDir/$Output/$proj_with_workflow-useful" ]]; then
    cat "$currentDir/$Output/$proj_with_workflow-useful" | cut -d',' -f2 > "$currentDir/tmp-access"
    cat "$currentDir/tmp-access" | sort | uniq > "$currentDir/tmp-access1"
    cp "$currentDir/tmp-access1" "$currentDir/$Output/$proj_with_workflow-useful" 

    rm "$currentDir/tmp-access1"
    rm "$currentDir/tmp-access"

    comm -12 <(sort -u "$currentDir/$Output/$proj_with_workflow-never-accessed") <(sort -u  "$currentDir/$Output/$proj_with_workflow-useful") >  "$currentDir/$Output/$proj_with_workflow-common"
fi

