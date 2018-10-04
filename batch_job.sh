#!/bin/bash 
#SBATCH -w isc17-c[02,03,04,05,08,09,10,12,14,23]
#SBATCH	--dependency=singleton
#SBATCH	--output=slurm/slurm-%j.txt
#SBATCH	--job-name=DDNIME

##SBATCH -w isc17-c[02-06,08-10,12-14,18]

#These nodes can be used with DDN IME
##SBATCH	--distribution=block


SCRIPT="$(readlink -f $0)"
SCRIPTPATH="$(dirname $SCRIPT)"
cd "$SCRIPTPATH"

function die() {
	echo "$1" && exit 1
}

function command_exists() {
	type "$1" &> /dev/null;
}

export MODULEPATH=/gsfs/betke/software/modules:$MODULEPATH


#module purge
#module load ddn/mvapich/3.1.4
#module load betke/hdf5/1.8.20
#module load betke/netcdf/4.4.1
#module load betke/ior/git
#module load betke/netcdf-bench/git-20171206
#module list


module purge
module load ddn/mvapich/3.1.4
module load betke/hdf5/1.8.20-ddn
module load betke/netcdf/4.4.1-ddn
module load betke/ior/git-ddn
module load betke/netcdf-bench/git-20171206-ddn
module list

type mpiexec 2>&1 || die "mpiexec not found"
type benchtool 2>&1 || die "benchtool not found"

#set -x
IOR="$(which ior)"
#IOR="/opt/ddn/ior/bin/IOR-mvapich"
NCBENCH="$(which benchtool)"
TESTDIR="/ime/isc18/perf"
#TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
TIMESTAMP="20171218_162418"

LUSTRE_TESTFILE="/esfs/isc18/perf/file"
FUSE_TESTFILE="/ime/isc18/perf/file"
IME_TESTFILE="ime:///esfs/isc18/perf/file"
OUTPUTDIR="./output"
SLURM_OUTPUT="slurm/slurm-%j.txt"
#set +x

WORKDIR="/gsfs/betke/git/manny-benchmark/scripts"
cd $WORKDIR

PROG_ARR=("$IOR")
#PROG_ARR=("$NCBENCH" "$IOR")
#NN_ARR=(1 2 4 8 12 16)
NN_ARR=(10 8 6 4 2 1)
#NN_ARR=(16 12 8 4 2 1)
PPN_ARR=(8 6 4 2 1)
TIME_ARR=(100)
XGEOM_ARR=($((8 * 2)))
YGEOM_ARR=($((8 * 8)))
#ZGEOM_ARR=(4 25 256 2560)
ZGEOM_ARR=(2560 256 25 4)
TYPE_ARR=("ind" "coll") #( "ind" "coll" ) 
IFACE_ARR=("ime" "mpio" "posix")
FS_ARR=("ime" "lustre" "fuse")
CHUNKED_ARR=("none" "-c=auto") #("none") # ( "none" "-c=auto" )
UNLIMITED_ARR=("none" "-u") # ( "none" "-u" )
#FILL_VALUE_ARR=("-F" "none") # "-F" )
FILL_VALUE_ARR=("none") # "-F" )


#####
SLURMDIR="$(dirname $SLURM_OUTPUT)"
mkdir -p $SLURMDIR

TDIR="$(dirname $IME_TESTFILE)"
srun --nodes=1 --ntasks=1 mkdir -p $TDIR
mkdir -p $OUTPUTDIR

function runTest(){
  local l_command="$1"
  local l_out="$2"
  local l_testdir="$3"
  local l_stripes="$4"
  local l_debug="$5"

  local l_wml="$(which mpiexec) -ppn 1 -np 1"

  local l_timestamp=$(date +"%Y%m%d_%H%M%S")
  echo "create $l_out"
  touch $l_out                         
  echo "${l_timestamp}" &>> $l_out
  echo "FILENAME $l_out" &>> $l_out 

  rm -rf $l_testdir
  mkdir -p $l_testdir
  lfs setstripe	-c $l_stripes $l_testdir
  echo "$l_command" | tee -a $l_out
  #eval "$l_command >> $l_out 2>&1"
  $l_command >> $l_out 2>&1
  lfs getstripe $l_testdir >> $l_out 2>&1
  rm -rf $l_testdir
}

#TESTFILE=$(makeOutputName $OUTPUTDIR $NN $PPN $T $X $Y $Z $TYPE $CHUNKED $UNLIMITED $FILLVALUE)
DEBUG=false


function makeOutputName() {
	local l_outdir="$1"
	local l_tag="$2"
	local l_count="${3}"
	local l_prog="$4"
	local l_nn="$5"
	local l_ppn="$6"
	local l_t="$7"
	local l_x="$8"
	local l_y="$9"
	local l_z="${10}"
	local l_type="${11}"
	local l_iface="${12}"
	local l_fs="${13}"
	local l_c="${14}"
	local l_u="${15}"
	local l_f="${16}"

	[[ "${l_c}" == "none" ]] && l_c="notset" || l_c="auto"
	[[ "${l_u}" == "none" ]] && l_u="notset" || l_u="set"
	[[ "${l_f}" == "none" ]] && l_f="notset" || l_f="set"

	local l_out="${l_outdir}/COUNT:${l_count}#TAG:${l_tag}#PROG:${l_prog}#NN:${l_nn}#PPN:${l_ppn}#TYPE:${l_type}#IFACE:${l_iface}#FS:${l_fs}#CHUNKED:${l_c}#FILLED:${l_f}#UNLIMITED:${l_u}#output:$l_t:${l_x}:${l_y}:${l_z}.txt"
	echo ${l_out}
}

for COUNT in $(seq 3); do
for PROG in ${PROG_ARR[@]}; do
for NN in ${NN_ARR[@]}; do
for PPN in ${PPN_ARR[@]}; do 
for T in ${TIME_ARR[@]}; do
for X in ${XGEOM_ARR[@]}; do 
for Y in ${YGEOM_ARR[@]}; do 
for Z in ${ZGEOM_ARR[@]}; do 
for TYPE in ${TYPE_ARR[@]}; do
for IFACE in ${IFACE_ARR[@]}; do
for FS in ${FS_ARR[@]}; do
for CHUNKED in ${CHUNKED_ARR[@]}; do
for UNLIMITED in ${UNLIMITED_ARR[@]}; do
for FILL_VALUE in ${FILL_VALUE_ARR[@]}; do
	BENCHFILE=$(makeOutputName $OUTPUTDIR $TIMESTAMP $COUNT $(basename $PROG) $NN $PPN $T $X $Y $Z $TYPE $IFACE $FS ${CHUNKED} ${UNLIMITED} ${FILL_VALUE})
	STRIPES=$(($NN * 2))

	if [ ! -e "${BENCHFILE}" ]; then
		if [[ $TYPE == "ind" && $UNLIMITED == "-u" ]]; then
			echo "skip ${BENCHFILE}, because -t=ind and -u are not supported"
		else


		#HNUM_ARR=("02" "03" "04" "05" "06" "08" "09" "10" "12" "13" "14" "23")
		#HNUM_ARR=("02" "03" "04" "05" "06" "08" "09" "10" "11" "14" "23" "12")
		#HNUM_ARR=("${HNUM_ARR[@]/#/isc17-c}")
		#HOST_LIST="$(IFS=, ; echo "${HNUM_ARR[*]}")"

		#HOST_LIST=isc17-c02,isc17-c03,isc17-c04,isc17-c05,isc17-c06,isc17-c08,isc17-c09,isc17-c10,isc17-c12,isc17-c13,isc17-c14,isc17-c18
		#HOST_LIST=isc17-c02,isc17-c03,isc17-c04,isc17-c05,isc17-c06,isc17-c08,isc17-c09,isc17-c10,isc17-c11,isc17-c12,isc17-c14,isc17-c23
		HOST_LIST=isc17-c02,isc17-c03,isc17-c04,isc17-c05,isc17-c08,isc17-c09,isc17-c10,isc17-c12,isc17-c14,isc17-c23


		#http://www.prace-ri.eu/best-practice-guide-generic-x86-html/
		#"$ADAPTIVE " \
		#"-genv IM_MONITOR_FILE /dev/shm/native_mon.%p " \
		#"-genv IM_CLIENT_NET_BUFFERS 32 " \

		WLM="$(which mpiexec) -ppn ${PPN} -np $(($NN*$PPN)) -hosts $HOST_LIST "
		WLM+="-genv IM_CLIENT_NET_BUFFERS 32 "
		WLM+="-genv MV2_NUM_HCAS 1 "
		WLM+="-genv MV2_CPU_BINDING_LEVEL core "
		WLM+="-genv MV2_CPU_BINDING_POLICY scatter "
		WLM+="-genv MV2_SHOW_CPU_BINDING 1 "

			#WLM="srun --nodes=$NN --ntasks-per-node=$PPN --ntasks=$(($NN*$PPN))"
			#WLM="mpiexec --allow-run-as-root -npernode $(($NN*$PPN)) -N $PPN" # for DDN IME system
			#WLM="/opt/ddn/mvapich/bin/mpiexec.hydra -ppn $PPN -np $(($PPN*$NN)) -hosts `nodeset -S ","  -e manny[600-607]`"

			case "$PROG" in 
				$IOR)
					echo "RUN $IOR"
					#set -x
					B=$(($X*$Y*$Z*4))
					S=$T

					if [[ "none" == "${CHUNKED}" ]]; then
					if [[ "none" == "${UNLIMITED}" ]]; then
					if [[ "none" == "${FILL_VALUE}" ]]; then
				
					$PARAMS="-e -g -z"
					PARAMS="-e -g"
				
					if [[ "lustre" == "${FS}" ]]; then
						if [[ "posix" == "${IFACE}" ]]; then
							if [[ "ind" == "${TYPE}" ]]; then
								runTest "$WLM $IOR -s $S -t $B -b $B -o $LUSTRE_TESTFILE $PARAMS -f ./tests/POSIX-individual" "${BENCHFILE}" "$(dirname $LUSTRE_TESTFILE)" "$STRIPES" "$DEBUG"
							fi
						elif [[ "mpio" == "${IFACE}" ]]; then
							if [[ "ind" == "${TYPE}" ]]; then
								runTest "$WLM $IOR -s $S -t $B -b $B -o $LUSTRE_TESTFILE $PARAMS -f ./tests/MPI-shared" "${BENCHFILE}" "$(dirname $LUSTRE_TESTFILE)" "$STRIPES" "$DEBUG"
							fi
						fi
					elif [[ "fuse" == "${FS}" ]]; then
						if [[ "posix" == "${IFACE}" ]]; then
							if [[ "ind" == "${TYPE}" ]]; then
								runTest "$WLM $IOR -s $S -t $B -b $B -o $FUSE_TESTFILE $PARAMS -f ./tests/POSIX-individual" "${BENCHFILE}" "$(dirname $FUSE_TESTFILE)" "$STRIPES" "$DEBUG"
							fi
						elif [[ "mpio" == "${IFACE}" ]]; then
							if [[ "ind" == "${TYPE}" ]]; then
								runTest "$WLM $IOR -s $S -t $B -b $B -o $FUSE_TESTFILE $PARAMS -f ./tests/MPI-shared" "${BENCHFILE}" "$(dirname $FUSE_TESTFILE)" "$STRIPES" "$DEBUG"
							fi
						fi
					elif [[ "ime" == "${FS}" ]]; then
						if [[ "ime" == "${IFACE}" ]]; then
							if [[ "ind" == "${TYPE}" ]]; then
								runTest "$WLM /opt/ddn/ior/bin/IOR-mvapich -s $S -t $B -b $B -o $IME_TESTFILE $PARAMS -a "IM"" "${BENCHFILE}" "$TESTDIR" "$STRIPES" "$DEBUG"
							fi
						fi
					fi
					fi
					fi
					fi
					
					#runTest "$WLM $IOR -a IM -s $S -t $B -b $B -o ime://$TESTFILE -e -f ./tests/MPI-shared" "shared" "${BENCHFILE}" "$TESTDIR" "$STRIPES" "$DEBUG"
					#set +x
					;;
				$NCBENCH)
					echo "RUN $NCBENCH"
					#set -x

					PARAMS=""
					if [[ "none" != "${CHUNKED}" ]]; then
						PARAMS+="${CHUNKED} " 
					fi
					if [[ "none" != "${UNLIMITED}" ]]; then
						PARAMS+="${UNLIMITED} " 
					fi
					if [[ "none" != "${FILL_VALUE}" ]]; then
						PARAMS+="${FILL_VALUE} " 
					fi

					if [[ "lustre" == "${FS}" ]]; then
						if [[ "mpio" == "${IFACE}" ]]; then
							runTest "$WLM $NCBENCH -f=$LUSTRE_TESTFILE -n=$NN -p=$PPN -d=$T:$(($X*$NN)):$(($Y*$PPN)):$Z -w -r -t=$TYPE $PARAMS" "${BENCHFILE}" "$(dirname ${LUSTRE_TESTFILE})" "$STRIPES" "$DEBUG"
						fi
					elif [[ "fuse" == "${FS}" ]]; then
						if [[ "mpio" == "${IFACE}" ]]; then
							runTest "$WLM $NCBENCH -f=$FUSE_TESTFILE -n=$NN -p=$PPN -d=$T:$(($X*$NN)):$(($Y*$PPN)):$Z -w -r -t=$TYPE $PARAMS" "${BENCHFILE}" "$(dirname ${FUSE_TESTFILE})" "$STRIPES" "$DEBUG"
						fi
					fi
					#set +x
					;;
				*)
					echo "$PROG not supported"
					exit 1
			esac
		fi
	else
		echo "skip $(readlink -f $BENCHFILE), already exists"
	fi
#exit

done
done
done
done
done
done
done
done
done
done
done
done
done
done

exit 0
