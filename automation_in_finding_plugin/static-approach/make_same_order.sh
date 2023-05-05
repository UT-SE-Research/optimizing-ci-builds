while read line
do
    unused_csv_file=$(echo $line | cut -d',' -f6)
    unused_dir=$(echo $line | cut -d',' -f7)
    out_line=$(grep -r "${unused_csv_file},target/${unused_dir}" "Result_1.csv")
    echo $out_line
    echo "${out_line}" >> Similar_Order_of_Google_sheet_Result.csv
done < $1
