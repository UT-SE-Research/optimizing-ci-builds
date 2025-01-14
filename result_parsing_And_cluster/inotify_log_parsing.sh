#!/bin/bash
if [[ $1 == "" || $2 == "" ]]; then
    #echo "please provide the inotify log(e.g., ci-analyzes/joda-time/.github/workflows/build/build/inotify-logs.csv)"
    echo "please provide the inotify log(e.g., ci-analyzes)"
    echo "please provide the run-result-status(e.g., data-dir/Github_Actions_original_date_20_April.csv)"
    #echo "please provide the project name (e.g., joda-time)"
    exit
fi
currentDir=$(pwd)

#in2csv -I --sheet "master_sheet" ~/Downloads/Github_Actions.xlsx > "$currentDir/data/master_cell.csv"

inotify_result_dir="$currentDir/data/Inotify-Parse-Result"
if [[ ! -d "$inotify_result_dir" ]]; then
	mkdir -p "$inotify_result_dir"
fi
grep -r ",success,success" $2 | grep -v "TRUE"  > "$currentDir/data/all_successful_job.csv"
echo $(pwd)
echo "$currentDir/data/all_successful_job.csv"

while read job_line #all_successful_job.csv
do
    x=0
    array=()
	echo $job_line
    inotify_log=$(echo ${job_line} | cut -d',' -f10 | cut -d'/' -f8-)
    branch_name=$(echo ${job_line} | cut -d',' -f10 | cut -d'/' -f7)
    proj_name=$(echo ${job_line} | cut -d',' -f10 | cut -d'/' -f8)
    job_name=$(echo ${job_line} | cut -d',' -f10 | cut -d'/' -f11- | sed 's;\/;-;g')
    #job_name=$(echo ${job_line} | cut -d',' -f4 | sed 's; ;_;g')
    echo "ci-analyzes/$inotify_log" >> "$currentDir/data/all_inotify-logs.csv"
    if [[ ! -d  ci-analyzes ]]; then
	    git clone https://github.com/UT-SE-Research/ci-analyzes.git 
	fi
    cd "$currentDir/ci-analyzes"
    git checkout ${branch_name}
	cd $currentDir    
    echo $inotify_log
    inotify="$currentDir/ci-analyzes/$inotify_log/inotify-logs.csv"
    echo $inotify
    total_line_of_inotify_log=$(cat $inotify | wc -l )
    arr_unique_line=()
    result="$inotify_result_dir/Output_${proj_name}_${job_name}.csv"
    echo  "branch,inotify_file_path,line_in_inotify_file,created file,actions_of_this_file,line_number_of_operations_index_in_yaml,Step_name(Line:step_name)" >> $result
    pos=0 # Need to know line_number of a line
    #echo $proj_name
    while read line
    do
        pos=$((pos+1))
        time=$(echo $line | cut -d';' -f1)
        created_file_dir=$(echo $line | cut -d';' -f2)
        created_file_name=$(echo $line | cut -d';' -f3)
        create_flag=0
        modify_flag=0
        full_file_name="${created_file_dir};${created_file_name};"
        
        if [[  -z $created_file_name ]]; then #Skipping if it is empty
            continue
        elif [[ $created_file_name == *"optimizing-ci-builds"* ]]; then #Skipping if it is optimizing-ci-analyze because that file is made by us
            continue
        elif [[ $created_file_name == *"starting_"* ]]; then #Skipping if it is optimizing-ci-analyze because that file is made by us
            continue

        elif [[ $(echo $line | grep "ISDIR" | wc -l) -eq 1 ]]; then
            echo "I AM ISDIR = $line"
            continue
        elif [[ " ${array[*]} " =~ " ${full_file_name} " ]]; then #Skipping if that file already visited
            #if [[ ${full_file_name} == *"site/apidocs/;options"* ]]; then
            #    echo "File already visited,substring matched, so stop, ="${full_file_name}
            #    echo "array=${array[*]}"
            #    exit
            #fi
            continue
        else
			#echo ${full_file_name}
            array+=(${full_file_name})
			x=$((x+1))
			# Iterate the loop to read and print each array element
            
            if [[ ! " ${arr_unique_line[*]} " =~ "${full_file_name}" ]]; then
                arr_unique_line+=(${full_file_name})
                grep -n "$full_file_name" $inotify >> "$inotify_result_dir/tmp.csv" #For each of the filename, I am adding everything of that filename in tmp.csv. Then I will process
                
                create_line=($(grep -n "CREATE" "$inotify_result_dir/tmp.csv" | cut -d':' -f1))  # to get the line numbe of the create
                modify_line=($(grep -n "MODIFY" "$inotify_result_dir/tmp.csv" | cut -d':' -f1)) # to get the line numbe of the modify
                #echo $modify_line
                boundary=0

                if (( ${#create_line[@]} )); then
                    create_flag=1
                fi
                if (( ${#modify_line[@]} )); then
                    modify_flag=1
                fi #echo not empty

                if [ $modify_flag -eq 1 ] && [ $create_flag -eq 0 ] ; then # If modify happens
                    boundary=${modify_line[-1]}
                elif [ $modify_flag -eq 0 ] && [ $create_flag -eq 1 ] ; then #If create happens
                    boundary=${create_line[-1]}
                else
                    if [ $modify_flag -eq 1 ] && [ $create_flag -eq 1 ] ; then # If both operation happens
                       if [[ ${modify_line[-1]} -gt ${create_line[-1]} ]]; then #to get the last element from the array, because mutilple create and modify might exists
                           boundary=${modify_line[-1]}
                           #echo "** modify later $boundary"
                       else
                           boundary=${create_line[-1]}
                       fi
                    else
                        echo "I am not modify or create"
                        continue
                    fi
                fi
                sed -n "1,$pos"p $inotify  >> "$inotify_result_dir/steps.txt" # Collecting which step is making this file
                starting_step=$(grep -n "starting_" "$inotify_result_dir/steps.txt" | tail -1)
                #echo $starting_step
                rm "$inotify_result_dir/steps.txt"
                #exit
                total_line=$(wc -l < "$inotify_result_dir/tmp.csv")
                tail -n +$((boundary+1)) "$inotify_result_dir/tmp.csv" >> "$inotify_result_dir/all_lines_after_last_modify_or_create.csv" #copy everything after last modify or create into another file
                
                #if [[ ${full_file_name} == *"site/apidocs/;options"* ]]; then
                    #echo "all_lines_after_last_modify_or_create ="${full_file_name}
                    #exit
                #fi
                count=$(grep -r "ACCESS"  "$inotify_result_dir/all_lines_after_last_modify_or_create.csv" | wc -l) #If access happens after last modify/create
                if [[ $count -gt 0 ]]; then # USEFUL FILE
                    echo $full_file_name   >> "$inotify_result_dir/${proj_name}_${job_name}_Useful.csv"
                else
                    echo $full_file_name   >> "$inotify_result_dir/${proj_name}_${job_name}_Unused.csv"
                fi
                #line_count=$((line_count + 1))

                #Collect all operation's execution sequence 
                arr_all_operation=($(cut -d';' -f1,4 "$inotify_result_dir/tmp.csv" ))
                #echo $arr_all_operation

                all_operation=""
                all_lines=""
                for i in "${arr_all_operation[@]}"
                do
                    #echo $i
                    if [[ "$i" =~ "CREATE" ]]; then
                        all_operation+="C"
                        all_lines+="$(echo $i |  cut -d':' -f1)_"

                    elif [[ "$i" =~ "MODIFY" ]]; then
                        all_operation+="M"
                        all_lines+="$(echo $i | cut -d':' -f1)_"
                    elif [[ "$i" =~ "ACCESS" ]]; then
                        all_lines+="$(echo $i | cut -d':' -f1)_"
                        all_operation+="A"
                    fi
                done
                remove_last_underline=$(echo $all_operation | rev | cut -d'_' -f2 | rev)
                last_op=$(echo ${remove_last_underline} | rev | cut -d'_' -f1 | rev)
                category="-"
                if [[ $last_op =~ "A" ]]; then
                    category="Accessed"
                elif [[ ! "$remove_last_underline" =~ "A" ]]; then
                    category="Never_accessed"
                elif [[ $last_op =~ "M" ]]; then
                    category="Unnecessary_modify"
                fi
                
                echo -n ${branch_name} >> $result
                echo -n ",$inotify" >> $result
                echo -n ",$total_line_of_inotify_log" >> $result
                echo -n ",$full_file_name" >> $result #This is a created file name
                
                echo -n ",$category" >> $result
                echo -n ",$remove_last_underline" >> $result
                ln=$(echo "$all_lines" | rev | cut -d'_' -f2- |rev)
                echo -n ",$ln"  >> $result
                echo -n ",$starting_step" >> $result
                echo "" >> $result

                rm "$inotify_result_dir/tmp.csv"
                rm "$inotify_result_dir/all_lines_after_last_modify_or_create.csv"
            fi
        fi
    done<"$inotify"
    cd $currentDir
done < "$currentDir/data/all_successful_job.csv"
#branch_name=$(git rev-parse --abbrev-ref HEAD)

#exit
