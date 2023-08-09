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

total_unused=0
total_used=0
comboDirsWithMoreUnusedFiles=0
all_dir=0
while read line
do 

    #cd "$currentDir/ccc/ci-analyzes"
    if [[ ${line} =~ ^\# ]]; then
        echo "Line starts with Hash $line"
        continue
    fi
    #cd $currentDir
    proj_name=$(echo $line | cut -d',' -f1) 
    workflow_path=$(echo ${line} | cut -d',' -f3)
    java_version=$(echo ${line}  | tr -d '\r' | cut -d',' -f17)
    mvn_command=$(echo ${line}  | tr -d '\r' | cut -d',' -f18)
    workflow_job_name=$(echo ${line} | cut -d',' -f10 | cut -d'/' -f11- | sed 's;\/;-;g') # example, Parsing(https://github.com/UT-SE-Research/ci-analyzes/tree/1680156014-f3221fe/soot/.github/workflows/ci/BuildAndTest)
    filename="${proj_name}_${workflow_job_name}"
    cat "data/Inotify-Parse-Result/${filename}_Useful.csv"  > "$currentDir/tmp/${filename}_Useful_sort_Prefix_remove.csv"
    rev Clustering-Both-Used-And-Unused-Directories/${filename}.csv | cut -d'/' -f2- | rev | sort | uniq -c > "$currentDir/tmp/$filename"

    while read line1
    do
        dirname=$(echo $line1 | cut -d' ' -f2)
        count_in_unused_dir=$(echo $line1 | cut -d' ' -f1)
        #echo $count_in_unused_dir
        #echo $dirname
        count_in_useful_dir=$(grep -r "$dirname/;" "$currentDir/tmp/${filename}_Useful_sort_Prefix_remove.csv" | wc -l)
        if [[ $count_in_unused_dir -gt $count_in_useful_dir ]]; then
            comboDirsWithMoreUnusedFiles=$((comboDirsWithMoreUnusedFiles + 1))
        fi
        percentage=$(echo "scale=3; $count_in_unused_dir / $count_in_useful_dir" | bc)
        echo "$proj_name,${workflow_path},${java_version},${mvn_command},${proj_name}_${workflow_job_name}.csv,$dirname,${count_in_unused_dir},${count_in_useful_dir},$percentage" >> "$result"
    done < "$currentDir/tmp/$filename" #Files from unused dir
    echo $total_unused
    echo $total_used
    #final_percentage=$(echo "scale=3; $total_unused/$total_used" | bc)
    #echo "percentage=$final_percentage"
    echo "comboDirsWithMoreUnusedFiles= $comboDirsWithMoreUnusedFiles"
    rm "$currentDir/tmp/$filename"
    rm "$currentDir/tmp/${filename}_Useful_sort_Prefix_remove.csv"

    rev Clustering-Used-Directories/${filename}.csv | cut -d'/' -f2- | rev | sort | uniq -c > "$currentDir/tmp/$filename"
    used_dir_count=$(wc -l < "$currentDir/tmp/$filename")
    echo "used=$used_dir_count"
    total_used=$((total_used + used_dir_count))
    rm "$currentDir/tmp/$filename"

    #echo "Clustering-Unused-Directories/${filename}.csv"
    rev Clustering-Unused-Directories/${filename}.csv | cut -d'/' -f2- | rev | sort | uniq -c > "$currentDir/tmp/$filename"
    unused_dir_count=$(wc -l < "$currentDir/tmp/$filename")
    echo "unused=$unused_dir_count"
    total_unused=$((total_unused + unused_dir_count))
    rm "$currentDir/tmp/$filename"

    all_dir=$(($all_dir + $used_dir_count + $unused_dir_count))
    echo $all_dir
done < $1
all_unusedDir_which_hasMoreUnusedFiles=$((comboDirsWithMoreUnusedFiles + total_unused))
#final_percentage=$(echo "scale=3; $comboDirsWithMoreUnusedFiles / $all_dir" | bc)
final_percentage=$(echo "scale=3; $all_unusedDir_which_hasMoreUnusedFiles / $all_dir" | bc)
echo "HELLO"
echo $all_unusedDir_which_hasMoreUnusedFiles
echo "$all_dir"
echo $final_percentage
