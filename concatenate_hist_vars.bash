#! /bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

file="$SCRIPT_DIR/varlist"

output_dir="/global/homes/c/cdkoven/cdkoven_m2467/trendy_2025_tseries_files"
# # Check if the file exists
# if [[ ! -f "$file" ]];
#     echo "Error: File '$file' not found."
#     exit 1
# fi

mkdir $output_dir/$1
ii=0
n_parallel=8
# Loop through each line in the file
while IFS= read -r line; do
    # 'IFS=' prevents leading/trailing whitespace trimming
    # 'read -r' prevents backslash interpretation

    ((ii++))
    
    echo "Processing: $line"
    if (( ii % n_parallel == 0 )); then
	ncrcat -4 -L 1 -cv $line $1.elm.h0.*.nc $output_dir/$1/$1.tseries.$line.nc
    else
	ncrcat -4 -L 1 -cv $line $1.elm.h0.*.nc $output_dir/$1/$1.tseries.$line.nc &
    fi

done < "$file"
