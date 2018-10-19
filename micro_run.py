#!/bin/bash 

export MODULEPATH=/gsfs/betke/software/modules:$MODULEPATH

module purge
module load betke/hdf5/1.8.20-ddn
module load betke/ior/git-ddn
module list

T=$((1 * 1024 * 1024))
B=$((128 * 1024 * 1024 * 1024))

IOR="$(which ior)"
LUSTRE_TESTFILE="/esfs/jtacquaviva/file2"
OUTPUTDIR="./output"
GENV="-genv IM_CLIENT_NET_BUFFERS 32 -genv MV2_NUM_HCAS 1 -genv MV2_CPU_BINDING_LEVEL core -genv MV2_CPU_BINDING_POLICY scatter -genv MV2_SHOW_CPU_BINDING 1"
MPIEXEC="/opt/ddn/mvapich/bin/mpiexec -ppn 1 -np 1 -hosts isc17-c17 $GENV"

$MPIEXEC $IOR -i 3  -s 1 -t $T  -b $B  -o $LUSTRE_TESTFILE -e -g -z -k -w
$MPIEXEC $IOR -i 3  -s 1 -t $T  -b $B  -o $LUSTRE_TESTFILE -e -g -z -k -D 1 -r
rm $LUSTRE_TESTFILE
