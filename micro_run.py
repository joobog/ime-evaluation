#!/bin/bash 

export MODULEPATH=/gsfs/betke/software/modules:$MODULEPATH

module purge
module load betke/hdf5/1.8.20-ddn
module load betke/ior/git-ddn
module list

LUSTRE_TESTFILE="/esfs/jtacquaviva/file"
ITERATIONS=1
IOR="$(which ior) -i $ITERATIONS -s 1 -t $((1 * 1024 * 1024)) -b $((128 * 1024 * 1024 * 1024)) -o $LUSTRE_TESTFILE -e -g -z -k"
MPIEXEC="/opt/ddn/mvapich/bin/mpiexec -ppn 1 -np 1 -hosts isc17-c17"

$MPIEXEC $IOR -w
$MPIEXEC $IOR -r -D $((5*60)) 
rm $LUSTRE_TESTFILE
