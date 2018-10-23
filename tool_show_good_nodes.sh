#/bin/bash 

function join_by() { 
	local IFS="$1"; shift; echo "$*"; 
}

cx4nodes=( isc17-c0{1..9} isc17-c{10..23} )
node_list=$( join_by , "${cx4nodes[@]}" )


IFS='' read -r -d '' script <<"EOF"
if [ -d /esfs/jtacquaviva ]; then
	cx4="$(lspci | grep ConnectX-4)"
	if [[ "" != $cx4 ]]; then
		echo 'ok'
	else 
		echo "no cx4"
	fi
else 
	echo "/esfs/ is not mounted"
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

echo "GOOD NODES:"
echo "${good_nodes[@]}"



