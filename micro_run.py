#!/bin/bash 

export MODULEPATH=/gsfs/betke/software/modules:$MODULEPATH

module purge
module load betke/hdf5/1.8.20-ddn
module load betke/ior/git-ddn
module list

LUSTRE_TESTFILE="/esfs/jtacquaviva/file"
ITERATIONS=3
IOR="$(which ior) -i $ITERATIONS -s 1 -t $((16 * 1024 )) -b $((128 * 1024 * 1024)) -o $LUSTRE_TESTFILE -e -g -z -k -D 100 "
MPIEXEC="/opt/ddn/mvapich/bin/mpiexec -ppn 1 -np 1 -hosts isc17-c05"

$MPIEXEC $IOR -w
$MPIEXEC $IOR -r -D $((5*60)) 
rm $LUSTRE_TESTFILE

