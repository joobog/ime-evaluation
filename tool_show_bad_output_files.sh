#!/bin/bash

force_delete=$1

find "./output" -type f -name "*.txt" -print0 |
	while IFS= read -r -d $'\0' fn; do
		status="$(grep -i "error" $fn)"
		if [[ "" != ${status} ]]; then
			if [[ "delete" == $force_delete ]]; then
				set -x
					rm $fn
				set +x
			else
				echo "Bad output: $fn"
			fi
		fi
	done
