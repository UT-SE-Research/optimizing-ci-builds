#!/bin/bash
if [[ $1 == "" || $2 == "" ]]; then
    echo "arg1-(e.g.,static-approach/Result_1.csv)"
    echo "arg2-(e.g.,RQ2-PR-Category)"
    exit
fi

#1-1 used (you tried one plugin, and it disabled 1 used directory/file) [??]
#1-1 unused (you tried one plugin, and it disabled 1 unused directory/file)[??]
#1-m used (you tried one plugin, and it disabled many used directory/file) [what is the number ??]
#1-m unused (you tried one plugin, and it disabled many unused directory/file)
#1-m both (you tried one plugin, and it disabled many unused and used directory/file)

while read line
do 

    disable_one_used=0
    disable_m_used=0
    
    disable_one_unused=0
    disable_m_unused=0

    disable_m_both_used_unused=0

    filename_prefix=$(echo $line | cut -d',' -f5 |cut -d'.' -f1)
    org_unused_dir=$(echo $line | cut -d',' -f6 |cut -d'/' -f2)


    if [[ "${org_unused_dir}" == "maven-status" ]]; then
        #echo "Not-Running-Dynamic=>$unused_csv_file,$workflow_file,$unused_dir,from-some-compiler-plugin" >> "$currentDir/Result.csv"
        rule_set=$((rule_set + 1))
        continue
    fi

    all_used_files=($(find $2 -name "${filename_prefix}*_used*${org_unused_dir}.txt"))
    all_unused_files=($(find $2 -name "${filename_prefix}*_unused*${org_unused_dir}.txt"))

    echo ${all_used_files[@]}
    for file in ${all_used_files[@]}; do
        filename=$(echo $file | cut -d'/' -f2)
        changed_to_unused=$(echo "$filename" | sed 's/used/unused/')
        echo "***file=$filename"
        echo $changed_to_unused
        exists=$(find $2 -name $changed_to_unused | wc -l)
        echo $exists
        if [[ $exists -eq 1 ]]; then
            echo "unused file found=============="
            disable_m_both_used_unused=$(( disable_m_both_used_unused + 1 ))
            continue
        fi
        total_line=$(wc -l $file | cut -d' ' -f1) 
        echo $total_line
        if [[ ${total_line} -gt 1 ]]; then
            disable_m_used=$((disable_m_used + 1))
        else
            disable_one_used=$((disable_one_used + 1))
        fi
    done
    echo  "all unused==>"
    echo ${all_unused_files[@]}

    for file in ${all_unused_files[@]}; do

        filename=$(echo $file | cut -d'/' -f2)
        changed_to_used=$(echo "$filename" | sed 's/unsed/used/')
        echo "===file=$filename"
        echo $changed_to_used
        exists=$(find $2 -name $changed_to_used | wc -l)
        echo $exists
        if [[ $exists -eq 1 ]]; then #Just skipping because in the upper loop, I already calculated this plugin
            echo "unused file found=============="
            continue
        fi

        total_line=$(wc -l $file | cut -d' ' -f1) 
        echo $total_line
        if [[ ${total_line} -gt 1 ]]; then
            disable_m_unused=$((disable_m_unused + 1))
        else
            disable_one_unused=$((disable_one_unused + 1))
        fi
    done

    echo "$filename_prefix","$org_unused_dir","${disable_one_used},$disable_m_used,$disable_one_unused,$disable_m_unused,$disable_m_both_used_unused" >> dynamic-characterstic.csv
    #echo "$filename_prefix and unused_dir= $unused_dir"

    #exit
done < $1
