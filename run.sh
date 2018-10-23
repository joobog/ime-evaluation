#!/bin/bash 

function force_exit {
    echo "Committing suicide (PID $$)"
    exit
}

trap force_exit SIGINT

# Provides a list of good hosts (that contains QDR connection)
function hosts() {
    num="$1"
    #HOST_LIST=( isc17-c04 isc17-c05 isc17-c06 isc17-c18 )

    HOST_LIST=( isc17-c04 isc17-c05 isc17-c06 isc17-c18 isc17-c01 isc17-c02 isc17-c03 isc17-c07 isc17-c08 isc17-c09 isc17-c11 isc17-c12 isc17-c13 isc17-c14 isc17-c15 isc17-c22 )


    hlist=${HOST_LIST[0]}
    for POS in $(seq 1 $(($num - 1))) ; do 
        hlist="$hlist,${HOST_LIST[$POS]}"
    done
    echo $hlist
}

export MODULEPATH=/esfs/jtacquaviva/software/modules:$MODULEPATH

module purge
module load betke/hdf5/1.8.20-ddn
module load betke/ior/git-ddn
module list


LUSTRE_TESTFILE_WRITE="/esfs/jtacquaviva/ioperf/file_write"
LUSTRE_TESTFILE_READ=""

ITERATIONS=3
IOR="$(which ior)"
MPIEXEC="/opt/ddn/mvapich/bin/mpiexec"

API_ARR=( "POSIX" "MPIIO" )
#NN_ARR=( 4 2 1 8 10 16)
NN_ARR=( 2 1 )
PPN_ARR=( 8 6 4 2 1 )
T_ARR=( $((10*1024*1024)) $((1*1024*1024)) $((100*1024)) $((16*1024)) )

for COUNT in $(seq 1); do
for NN in ${NN_ARR[@]}; do 
for T in ${T_ARR[@]}; do 
for PPN in ${PPN_ARR[@]}; do 
for API in ${API_ARR[@]}; do 

    BENCHFILE="./output/COUNT:$COUNT#NN:$NN#PPN:$PPN#API:$API#T:$T.txt"

	if [ ! -e "${BENCHFILE}" ]; then
		OUTDIR="$(dirname $BENCHFILE)"
        if [ ! -d $OUTDIR ]; then
		mkdir $OUTDIR
        fi
        touch $BENCHFILE

        IOR_API_OPTS=""
        if [[ "POSIX" == $API ]]; then
            IOR_API_OPTS="-F"
            LUSTRE_TESTFILE_READ="/esfs/jtacquaviva/indread$NN/file"
        elif [[ "MPIIO" == $API ]]; then
            IOR_API_OPTS=""
            LUSTRE_TESTFILE_READ="/esfs/jtacquaviva/file_read"
        fi


        IOR_PARAMS="-i $ITERATIONS -s 1 -t $T -b $((4800 * 1024 * 1024 * 32 / $PPN)) -D $((120)) -a $API $IOR_API_OPTS -e -g -z -k"
	    ENVVAR="-genv MV2_NUM_HCAS 1 -genv MV2_CPU_BINDING_LEVEL core -genv MV2_CPU_BINDING_POLICY scatter"
        MPIEXEC_PARAMS=" -ppn $PPN -np $(($NN * $PPN)) $ENVVAR --hosts $(hosts $NN) "

        TESTDIR="$(dirname $LUSTRE_TESTFILE_WRITE)"
        if [ -d $TESTDIR ]; then
		rm -r $TESTDIR
        fi
        mkdir -p $TESTDIR 
        lfs setstripe	-c $((2 * $NN)) $TESTDIR
	(
        set -x
        $MPIEXEC $MPIEXEC_PARAMS $IOR $IOR_PARAMS -o $LUSTRE_TESTFILE_WRITE -w | tee -a $BENCHFILE
        $MPIEXEC $MPIEXEC_PARAMS /esfs/jtacquaviva/git/ime-evaluation/drop_caches.sh
        $MPIEXEC $MPIEXEC_PARAMS $IOR $IOR_PARAMS -o $LUSTRE_TESTFILE_READ -r | tee -a $BENCHFILE
        set +x
	) 2> >(tee -a $BENCHFILE)
        lfs getstripe $TESTDIR | tee -a $BENCHFILE
	else
		echo "skip $(readlink -f $BENCHFILE), already exists"
	fi

done
done
done
done
done

