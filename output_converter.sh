#!/bin/bash

find "./output_v2" -type f -name "*.txt" -print0 |
	while IFS= read -r -d $'\0' fn; do
		headln="$(grep Finished $fn -n | head -n 1 | cut -d":" -f 1)"
		totalln=$(wc -l $fn | cut -f 1 -d" ")
		tailln=$(($totalln - $headln))

		echo $fn $headln $tailln $totalln
		bn=$(basename $fn)

		extension="${bn##*.}"
		filename="${bn%.*}"

		count=$(awk -F# '{print $1}' <<< $filename)
		nn=$(awk -F# '{print $2}' <<< $filename)
		ppn=$(awk -F# '{print $3}' <<< $filename)
		api=$(awk -F# '{print $4}' <<< $filename)
		t=$(awk -F# '{print $5}' <<< $filename)

		FNEXT="$count#$nn#$ppn#$api#$t#APP:ior-default#FS:lustre#IOTYPE:random#ACCESSTYPE:read#STRIPING:yes"

		cp $fn "merged_output/$FNEXT.$extension" 
	done


find "./output" -type f -name "*.txt" -print0 |
	while IFS= read -r -d $'\0' fn; do
		headln="$(grep Finished $fn -n | head -n 1 | cut -d":" -f 1)"
		totalln=$(wc -l $fn | cut -f 1 -d" ")
		tailln=$(($totalln - $headln))

		echo $fn $headln $tailln $totalln
		bn=$(basename $fn)

		extension="${bn##*.}"
		filename="${bn%.*}"

		STRIPING="yes"
		if [[ "" != $(echo $bn| grep MPIIO) ]]; then
			STRIPING="no"
		fi

		FNEXT="APP:ior-default#FS:lustre#IOTYPE:random"

		head -n $headln $fn > "merged_output/$filename#$FNEXT#ACCESSTYPE:write#STRIPING:yes.$extension" 
		
		outfnread="merged_output/$filename#$FNEXT#ACCESSTYPE:read#STRIPING:$STRIPING.$extension"

		if [ -e $outfnread ]; then
			echo "stopping $outfnread, already exists"
			exit
		fi

		tail -n $tailln $fn > $outfnread
	done


