cd -P -- "$(dirname -- "$0")"

#####################################################

WORKDIR=`pwd`

mkdir -p app bin
rm -rf ./tmp/*
rm -f ./tmp
mkdir -p /dev/shm/${USER}
ln -s /dev/shm/${USER} tmp
rm -rf ./app/*

cd tmp

export JOBS=8

PAPI_STATIC=""
PAPI_STATIC="--with-shared-lib=no --with-static-tools --with-static-lib=yes"

MPI_STATIC=""
MPI_STATIC="--enable-static --disable-shared"

VT_STATIC=""
VT_STATIC="--enable-static=yes --enable-shared=no"

OTF_STATIC="$VT_STATIC"

ZLIB_STATIC=""
ZLIB_STATIC="--static"

#####################################################################
tar xzf ${WORKDIR}/arc/papi-4.1.4.tar.gz
cd papi-4.1.4/
cd src
./configure --prefix=${WORKDIR}/app/papi $PAPI_STATIC --with-components=net
cd components/net
./configure --prefix=${WORKDIR}/app/papi
cd ..
cd ..
make -j $JOBS
sync
make 
sync
make install 
cd ..
cd ..

export PAPI=${WORKDIR}/app/papi
export PAPI_BIN=${WORKDIR}/app/papi/bin
export PAPI_LIB=${WORKDIR}/app/papi/lib

#####################################################################
tar xjf ${WORKDIR}/arc/openmpi-1.5.4.tar.bz2 
cd openmpi-1.5.4/
./configure --prefix=${WORKDIR}/app/mpi $MPI_STATIC --disable-vt --enable-contrib-no-build=libompitrace,vt
make -j $JOBS
sync
make
make install
cd ..
 
export MPI=${WORKDIR}/app/mpi 
export MPI_BIN=${WORKDIR}/app/mpi/bin
export MPI_LIB=${WORKDIR}/app/mpi/lib

#####################################################################
tar xf ${WORKDIR}/arc/zlib-1.2.5.tar 
cd zlib-1.2.5/
./configure --prefix=${WORKDIR}/app/zlib ${ZLI_STATIC} --64
make -j $JOBS
make install
cd ..

export ZLIB=${WORKDIR}/app/zlib

#####################################################################
tar xzf ${WORKDIR}/arc/VampirTrace-5.11.2.tar.gz
cd VampirTrace-5.11.2/
./configure --prefix=${WORKDIR}/app/vt $VT_STATIC --with-zlib-dir=${ZLIB} --with-mpi-dir=$MPI --with-papi-dir=$PAPI 
make  -j $JOBS
sync
make
make install
cd ..

export VT=${WORKDIR}/app/vt
export VT_BIN=${WORKDIR}/app/vt/bin
export VT_LIB=${WORKDIR}/app/vt/lib

#####################################################################
echo "export PATH=${WORKDIR}/bin:$PAPI_BIN:$MPI_BIN:$VT_BIN:${PATH}
export LD_LIBRARY_PATH=$PAPI_LIB:$MPI_LIB:$VT_LIB
" >${WORKDIR}/bin/setup.sh
chmod +x ${WORKDIR}/bin/setup.sh

#####################################################################
. ${WORKDIR}/bin/setup.sh
tar xjf ${WORKDIR}/arc/IOR-2.10.3_with_VampirTrace.tar.bz2 
cd IOR
. ./make_vt.sh 
cp src/C/IOR ${WORKDIR}/bin/
cd ..


