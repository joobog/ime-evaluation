#!/bin/bash



API_ARR=( "POSIX" "MPIIO" )
NN_ARR=( 4 2 1 8  16)
PPN_ARR=( 8 6 4 2 1 )
T_ARR=( $((10*1024*1024)) $((1*1024*1024)) $((100*1024)) $((16*1024)) )


done="$(find output -type f | wc -l)"
todo=$((${#API_ARR[@]} * ${#NN_ARR[@]} * ${#PPN_ARR[@]} * ${#T_ARR[@]}))
remains=$(($todo - $done))

echo "$(($remains * 2 * 6 / 60)) h"
