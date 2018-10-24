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

    #HOST_LIST=( isc17-c04 isc17-c05 isc17-c06 isc17-c18 isc17-c01 isc17-c02 isc17-c03 isc17-c07 isc17-c08 isc17-c09 isc17-c11 isc17-c12 isc17-c13 isc17-c14 isc17-c15 isc17-c22 )
 HOST_LIST=( isc17-c04 isc17-c05 isc17-c06 isc17-c07 isc17-c08 isc17-c09 isc17-c11 isc17-c12 isc17-c13 isc17-c14 isc17-c15 isc17-c18 isc17-c22 isc17-c01 isc17-c02 isc17-c03 )

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


LUSTRE_TESTFILE=""

ITERATIONS=3
IOR="$(which ior)"
MPIEXEC="/opt/ddn/mvapich/bin/mpiexec"


TYPE_ARR=( "read" )
API_ARR=( "MPIIO" )
#NN_ARR=( 4 2 1 8 10 16)
NN_ARR=( 1 2 4 8 16)
PPN_ARR=( 8 4 1 6 2)
T_ARR=( $((10*1024*1024)) $((1*1024*1024)) $((100*1024)) $((16*1024)) )


for COUNT in $(seq 1); do
for TYPE in ${TYPE_ARR[@]}; do
for NN in ${NN_ARR[@]}; do 
for T in ${T_ARR[@]}; do 
for PPN in ${PPN_ARR[@]}; do 
for API in ${API_ARR[@]}; do 

    BENCHFILE="./output_v2/COUNT:$COUNT#NN:$NN#PPN:$PPN#API:$API#T:$T#TYPE:$TYPE.txt"

	if [ ! -e "${BENCHFILE}" ]; then
		OUTDIR="$(dirname $BENCHFILE)"
        if [ ! -d $OUTDIR ]; then
		mkdir $OUTDIR
        fi
        touch $BENCHFILE

        IOR_API_OPTS=""

        IOR_TYPE_OPTS=""
        if [[ "read" == $TYPE ]]; then
            IOR_TYPE_OPTS="-r"
            $MPIEXEC $MPIEXEC_PARAMS /esfs/jtacquaviva/git/ime-evaluation/drop_caches.sh
            if [[ "POSIX" == $API ]]; then
                IOR_API_OPTS="-F"
                LUSTRE_TESTFILE="/esfs/jtacquaviva/indread$NN/file"
            elif [[ "MPIIO" == $API ]]; then
                IOR_API_OPTS=""
                LUSTRE_TESTFILE="/esfs/jtacquaviva/sharedread$NN/file"
            fi

        elif [[ "write" == $TYPE ]]; then
            IOR_TYPE_OPTS="-w"
            LUSTRE_TESTFILE="/esfs/jtacquaviva/ioperf/file_write"

            TESTDIR="$(dirname $LUSTRE_TESTFILE)"
            if [ -d $TESTDIR ]; then
            rm -r $TESTDIR
            fi
            mkdir -p $TESTDIR 
            lfs setstripe	-c $((2 * $NN)) $TESTDIR
            lfs getstripe $TESTDIR | tee -a $BENCHFILE
        fi


        IOR_PARAMS="-i $ITERATIONS -s 1 -t $T -b $((4800 * 1024 * 1024 * 32 / $PPN)) -D $((30)) -a $API $IOR_API_OPTS -e -g -z -k"
	    ENVVAR="-genv MV2_NUM_HCAS 1 -genv MV2_CPU_BINDING_LEVEL core -genv MV2_CPU_BINDING_POLICY scatter"
        MPIEXEC_PARAMS=" -ppn $PPN -np $(($NN * $PPN)) $ENVVAR --hosts $(hosts $NN) "

	(
        set -x
        $MPIEXEC $MPIEXEC_PARAMS $IOR $IOR_PARAMS -o $LUSTRE_TESTFILE $IOR_TYPE_OPTS | tee -a $BENCHFILE
        set +x
	) 2> >(tee -a $BENCHFILE)
	else
		echo "skip $(readlink -f $BENCHFILE), already exists"
	fi

done
done
done
done
done
done

