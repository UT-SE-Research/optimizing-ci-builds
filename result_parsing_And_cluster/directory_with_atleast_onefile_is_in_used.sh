#!/bin/bash

if [[ $1 == "" ]]; then
	echo "plz give project list in a csv (projects_name.csv)"
    exit
fi
outputDir="$2"
if [[ ! -d "$outputDir" ]]; then
    mkdir "$outputDir"
fi
uses_name="${1}_$3" #$(echo $1 | rev | cut -d'/' -f1 | rev) #normally it will be never-accessed
never_access=${uses_name}
#===========Which are never ever accessed=========

cat "data/Inotify-Parse-Result/$uses_name.csv"  > "$outputDir/${never_access}_sort_Prefix_remove.csv"
#======================================== useful.csv ($3)===============================

uses_name="${1}_$4" #$(echo $3 | rev | cut -d'/' -f1 | rev) #normally it will be useful
useful=${uses_name}

cat "data/Inotify-Parse-Result/$uses_name.csv"  > "$outputDir/${useful}_sort_Prefix_remove.csv"
echo "$outputDir/${useful}_sort_Prefix_remove.csv"
blacklist=(".git" ".github" "optimizing-ci-builds-ci-analysis")
while read line
do

    flag=0
    #after_target="${line#*target}"
    #echo "$after_target"
    #if [[ -z $after_target ]]; then
        upto_last_dir_name=$(echo $line | rev | cut -d'/' -f2- | rev) #Collect last dir
        directory_exists_useful_and_unused=$(grep -r "$upto_last_dir_name/;" "$outputDir/${never_access}_sort_Prefix_remove.csv" | wc -l) # taking files only in the occurance in the unused dir.
        if [[ $directory_exists_useful_and_unused -gt 0 ]]; then
            for blacklist_item in ${blacklist[@]};
            do
                count=$(echo  $upto_last_dir_name | grep -o "$blacklist_item" | wc -l)
                echo "I AM SHANTO******************* $line, last_dir=$upto_last_dir_name"
                echo $count
                if [[ $count -gt 0 ]]; then
                    flag=1
                    break
                fi
            done 
            if [[ $flag -eq 0 ]]; then
                all_files_whose_directory_is_shared_accross_both_useful_and_unused=$(grep -r "$upto_last_dir_name/;" "$outputDir/${never_access}_sort_Prefix_remove.csv") # taking files only in the occurance in the unused dir.
                #To save the result
                for res in ${all_files_whose_directory_is_shared_accross_both_useful_and_unused[@]}; do
                    echo "$res" >> "$outputDir/${1}.csv"
                done
            fi

        fi
   # fi
    #echo "$all_files_whose_directory_is_shared_accross_both_useful_and_unused"
done <  "$outputDir/${useful}_sort_Prefix_remove.csv"

rm "$outputDir/${useful}_sort_Prefix_remove.csv"
rm "$outputDir/${never_access}_sort_Prefix_remove.csv"
