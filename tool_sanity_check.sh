#!/bin/bash


NN_ARR=( 4 2 1 8 10 12 14 16)
PPN_ARR=( 8 6 4 2 1 )
T_ARR=( $((10*1024*1024)) $((1*1024*1024)) $((100*1024)) $((16*1024)) )


res="OK"

for COUNT in $(seq 1); do
for NN in ${NN_ARR[@]}; do 
for T in ${T_ARR[@]}; do 
for PPN in ${PPN_ARR[@]}; do 

	#datasize=$((130 * 1024 * 1024 * 1020 / $PPN))
	datasize=$((4800 * 1024 * 1024 * 32 / $PPN))
	remain=$(( $datasize - ($datasize / $T * $T) ))
	if [ 0 -ne $remain ]; then
		echo "Bad IOR paramters: NN=$NN, PPN=$PPN, T=$T, DS=$datasize"
		res="FAILED"
	fi

done
done
done
done

echo $res
