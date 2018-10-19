#!/bin/bash 

function force_exit {
    echo "Committing suicide (PID $$)"
    exit
}

trap force_exit SIGINT

# Provides a list of good hosts (that contains QDR connection)
function hosts() {
    num="$1"
    HOST_LIST=( isc17-c02 isc17-c03 isc17-c04 isc17-c05 isc17-c08 isc17-c09 isc17-c10 isc17-c12 isc17-c14 isc17-c23 )
    hlist=${HOST_LIST[1]}
    for POS in $(seq 2 $num) ; do 
        hlist="$hlist,${HOST_LIST[$POS]}"
    done
    echo $hlist
}


export MODULEPATH=/gsfs/betke/software/modules:$MODULEPATH

module purge
module load betke/hdf5/1.8.20-ddn
module load betke/ior/git-ddn
module list

LUSTRE_TESTFILE="/esfs/jtacquaviva/iorperf/file"
ITERATIONS=3
IOR="$(which ior)"
MPIEXEC="/opt/ddn/mvapich/bin/mpiexec"

NN_ARR=(1)
PPN_ARR=(8 6 4 2 1)
T_ARR=( $((16*1024)) $((100*1024)) $((1024*1024)) $((10240*1024)) )
API_ARR=("MPIIO" "POSIX")

for COUNT in $(seq 5); do
for NN in ${NN_ARR[@]}; do 
for PPN in ${PPN_ARR[@]}; do 
for T in ${T_ARR[@]}; do 
for API in ${API_ARR[@]}; do 

    BENCHFILE="./output/COUNT:$COUNT#NN:$NN#PPN:$PPN#API:$API#T:$T.txt"

	if [ ! -e "${BENCHFILE}" ]; then
        OUTDIR="$(dirname $BENCHFILE)"
        if [ ! -d $OUTDIR ]; then
            mkdir $OUTDIR
        fi
        touch $BENCHFILE

        IOR_PARAMS="-i $ITERATIONS -s 1 -t $T -b $((130 * 1024 * 1024 * 1020)) -o $LUSTRE_TESTFILE -a $API -e -g -z -k"
        MPIEXEC_PARAMS=" -ppn $PPN -np $NN -hosts $(hosts $NN)"

        TESTDIR="$(dirname $LUSTRE_TESTFILE)"
        if [ -d $TESTDIR ]; then
            rm $TESTDIR
        fi
        mkdir -p $TESTDIR 
        lfs setstripe	-c $((2 * $NN)) $TESTDIR
        $MPIEXEC $MPIEXEC_PARAMS $IOR $IOR_PARAMS -w | tee -a $BENCHFILE
        $MPIEXEC $MPIEXEC_PARAMS $IOR $IOR_PARAMS -r -D $((5*60)) | tee -a $BENCHFILE
        rm $LUSTRE_TESTFILE
        lfs getstripe $TESTDIR | tee -a $BENCHFILE
	else
		echo "skip $(readlink -f $BENCHFILE), already exists"
    fi

done
done
done
done
done

