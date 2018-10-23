#!/bin/bash 

export MODULEPATH=/esfs/jtacquaviva/software/modules:$MODULEPATH

module purge
module load betke/hdf5/1.8.20-ddn
module load betke/ior/git-ddn
module list

NN=16
NODES='isc17-c01,isc17-c02,isc17-c03,isc17-c04,isc17-c05,isc17-c06,isc17-c07,isc17-c08,isc17-c09,isc17-c11,isc17-c12,isc17-c13,isc17-c14,isc17-c15,isc17-c18,isc17-c22'

LUSTRE_TESTFILE="/esfs/jtacquaviva/indread${NN}/file"
TESTDIR="$(dirname $LUSTRE_TESTFILE)"
mkdir $TESTDIR
lfs setstripe -c $(($NN * 2)) $TESTDIR
ITERATIONS=1
IOR="$(which ior) -i $ITERATIONS -s 1 -t $((16 * 1024 * 1024)) -b $((132 * 1024 * 1024 * 1020)) -o $LUSTRE_TESTFILE -a POSIX -F -e -g -k -w"
ENVVAR="-genv MV2_NUM_HCAS 1 -genv MV2_CPU_BINDING_LEVEL core -genv MV2_CPU_BINDING_POLICY scatter"
MPIEXEC="/opt/ddn/mvapich/bin/mpiexec -ppn 8 -np $((8*$NN)) $ENVVAR -hosts isc17-c04,isc17-c05"

set -x
$MPIEXEC $IOR 
#$MPIEXEC $IOR -r -D $((5*60)) 
-set +x
#rm $LUSTRE_TESTFILE

