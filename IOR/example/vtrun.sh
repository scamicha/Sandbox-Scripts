#!/bin/bash

CPUS=16
#CPUS=96

if [ -z $1 ]
   then CFG=ior.cfg
else
   CFG=$1
fi

set -x
set -e

cd `dirname ${0}`

BPWD=`pwd`

TIMESTAMP=`date +%y%m%d%H%M%S`
mkdir ${PWD}/log/${TIMESTAMP}

cp $CFG ${PWD}/log/${TIMESTAMP}
cp machinefile ${PWD}/log/${TIMESTAMP}

cd ${PWD}/log/${TIMESTAMP}
mpirun --mca btl self,sm,tcp -x VT_IOTRACE=yes -x VT_MAX_MPI_COMMS=10000 -machinefile machinefile -np $CPUS --bynode --output-filename ior IOR -f $CFG
echo "mpirun --mca btl self,sm,tcp -x VT_IOTRACE=yes -x VT_MAX_MPI_COMMS=10000 -machinefile machinefile -np $CPUS --bynode --output-filename ior IOR_mpi_vt -f $CFG" >./mpirun.txt

