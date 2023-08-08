if [[ $1 == "" ]]; then
    echo "Give the csv that is generated from (data/all_successful_job.csv)"
    exit
fi

currentDir=$(pwd)
mkdir "$currentDir/tmp"
#cut -d',' -f1-5,15 "$currentDir/data/master_cell.csv" > 
#ssconvert  ~/Downloads/master_cell.xlsx data/all_proj.csv
#exit
#branch_name=$(echo $1 | rev | cut -d'/' -f1 | rev | cut -d'-' -f2- | cut -d'.' -f1)
#echo $branch_name
#if [[ ! -d "ccc/ci-analyzes" ]]; then
#    git clone https://github.com/UT-SE-Research/ci-analyzes.git "$currentDir/ccc/ci-analyzes/"
#fi
result="$currentDir/percentage_of_directories_that_have_more_unused_files_than_useful_ones.csv"
echo "proj_name,workflow_path,java_version,mvn_command,unused_csv_file,count_in_unused_dir,count_in_useful_dir"  >> "$result"

while read line
do 

    #cd "$currentDir/ccc/ci-analyzes"
    if [[ ${line} =~ ^\# ]]; then
        echo "Line starts with Hash $line"
        continue
    fi
    #branch_name=$(echo $line | cut -d',' -f15) 
    #echo $branch_name
    #git checkout ${branch_name}
    #exit
    cd $currentDir
    proj_name=$(echo $line | cut -d',' -f1) 
    #echo -n ""  >> $result
    workflow_path=$(echo ${line} | cut -d',' -f3)
    java_version=$(echo ${line}  | tr -d '\r' | cut -d',' -f17)
    mvn_command=$(echo ${line}  | tr -d '\r' | cut -d',' -f18)
    workflow_job_name=$(echo ${line} | cut -d',' -f10 | cut -d'/' -f11- | sed 's;\/;-;g') # example, Parsing(https://github.com/UT-SE-Research/ci-analyzes/tree/1680156014-f3221fe/soot/.github/workflows/ci/BuildAndTest)
    #echo -n "$proj_name,${workflow_path},${java_version},${mvn_command},${proj_name}_${workflow_job_name}.csv" >> "$result"

    #echo "${proj_name}_${workflow_job_name}"
    filename="${proj_name}_${workflow_job_name}"
    cat "data/Inotify-Parse-Result/${filename}_Useful.csv"  > "$currentDir/tmp/${filename}_Useful_sort_Prefix_remove.csv"

    rev Clustering-Both-Used-And-Unused-Directories/${filename}.csv | cut -d'/' -f2- | rev | sort | uniq -c > "$currentDir/tmp/$filename"
    while read line1
    do
        dirname=$(echo $line1 | cut -d' ' -f2)
        count_in_unused_dir=$(echo $line1 | cut -d' ' -f1)
        echo $count_in_unused_dir
        echo $dirname
        count_in_useful_dir=$(grep -r "$dirname/;" "$currentDir/tmp/${filename}_Useful_sort_Prefix_remove.csv" | wc -l)
        percentage=$(echo "scale=3; $count_in_unused_dir / $count_in_useful_dir" | bc)
        echo "$proj_name,${workflow_path},${java_version},${mvn_command},${proj_name}_${workflow_job_name}.csv,$dirname,${count_in_unused_dir},${count_in_useful_dir},$percentage" >> "$result"
    done < "$currentDir/tmp/$filename" #Files from unused dir
done < $1



