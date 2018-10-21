#/bin/bash 

function join_by() { 
	local IFS="$1"; shift; echo "$*"; 
}


cx4nodes=( \
isc17-c02 \
isc17-c03 \
isc17-c04 \
isc17-c05 \
isc17-c06 \
isc17-c07 \
isc17-c08 \
isc17-c09 \
isc17-c10 \
isc17-c11 \
isc17-c12 \
isc17-c13 \
isc17-c14 \
isc17-c15 \
isc17-c18 \
isc17-c19 \
isc17-c20 \
isc17-c22 \
isc17-c23 \
isc17-c01 \
)

#cx4nodes=( isc17-c0{1..9} isc17-c{10..22} )
node_list=$( join_by , "${cx4nodes[@]}" )


IFS='' read -r -d '' script <<"EOF"
if [ -d /esfs/jtacquaviva ]; then
	if [ -d /gsfs/betke ]; then
		echo 'ok'
	else 
		echo "failed: $(hostname) /gsfs/ is not mounted"
	fi
else 
	echo "failed: $(hostname) /esfs/ is not mounted"
fi
EOF

declare -a good_nodes
for node in ${cx4nodes[@]}; do
	#echo "ping $node"
	status=$(ping -c1 $node | grep Unreachable)
	if [[ "" == $status ]]; then
		check=$(ssh $node "$script")
		if [[ "ok" == ${check} ]]; then
			good_nodes=( ${good_nodes[@]} $node )
		else 
			echo "$node failed with: $check"
		fi
	else 
		echo "$node is unreachable"
	fi
done

echo "${good_nodes[@]}"
echo $( join_by , "${good_nodes[@]}" )



