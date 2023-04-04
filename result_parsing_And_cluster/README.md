#To parse all inotify log first, run the following command
bash inotify_log_parsing.sh ci-analyzes/ data-dir/master_cell.csv

#bash inotify_log_parsing.sh ci-analyzes/ data/master_cell.csv

bash runAll.sh data/all_successful_job.csv

```bash  find_which_files_are_accessed_and_which_are_not.sh ../../ci-analyzes/Algorithms/1672727079/.github/workflows/check/build/ Algorithm```

```bash make_cluster_for_each_category.sh Output/JSQlParser-never-accessed  "" Output/JSQlParser-useful JSQlParser```

To parse all unused files=>

cat Clustering-Unused-Directories/* | sort -k1 -n -r -t' ' | tr -s " " | uniq  > all_unnecessary.csv

bash csv_generate.sh Clustering-Unused-Directories/ Parsed-Results-of-Different-clusters/Result_Unnnecessary_file.csv Parsed-Results-of-Different-clusters/Histogram_for_each_unnecessary_file.csv

bash csv_generate.sh Clustering-Used-Directories/ Parsed-Results-of-Different-clusters/Result_Used_file.csv Parsed-Results-of-Different-clusters/Histogram_for_each_used_file.csv

#bash csv_generate_2.sh Clustering-Unused-Directories/ Parsed-Results-of-Different-clusters/Histogram_for_each_unnecessary_file.csv


