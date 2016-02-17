#!/usr/bin/env bash

pushd .

WORKDIR=`pwd`

# create a new folder to store external tools
mkdir -p $WORKDIR/external-tools

# install htslib
cd $WORKDIR/external-tools
curl -L https://github.com/samtools/htslib/releases/download/1.3/htslib-1.3.tar.bz2 > htslib-1.3.tar.bz2
tar xjvf htslib-1.3.tar.bz2
cd htslib-1.3
make
PATH=$PATH:$WORKDIR/external-tools/htslib-1.3
LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$WORKDIR/external-tools/htslib-1.3

# install samtools, compile against htslib
cd $WORKDIR/external-tools
curl -L http://downloads.sourceforge.net/project/samtools/samtools/1.3/samtools-1.3.tar.bz2 > samtools-1.3.tar.bz2
tar xjvf samtools-1.3.tar.bz2 
cd samtools-1.3
./configure --with-htslib=../htslib-1.3
make
PATH=$PATH:$WORKDIR/external-tools/samtools-1.3

echo "installed samtools"
samtools --version

if [ $? != 0 ]; then
    exit 1
fi

# install bcftools
cd $WORKDIR/external-tools
curl -L https://github.com/samtools/bcftools/releases/download/1.3/bcftools-1.3.tar.bz2 > bcftools-1.3.tar.bz2
tar xjf bcftools-1.3.tar.bz2
cd bcftools-1.3
./configure --with-htslib=../htslib-1.3
make
PATH=$PATH:$WORKDIR/external-tools/bcftools-1.3

echo "installed bcftools"
bcftools --version

if [ $? != 0 ]; then
    exit 1
fi

popd

# install code from the repository
python setup.py install

# change into tests directory. Otherwise,
# 'import pysam' will import the repository,
# not the installed version. This causes
# problems in the compilation test.
cd tests

# create auxilliary data
echo
echo 'building test data'
echo 
make -C pysam_data
make -C cbcf_data

# run nosetests
# -s: do not capture stdout, conflicts with pysam.dispatch
# -v: verbose output
nosetests -s -v 

# build source tar-ball and test installation from tar-ball
cd ..
python setup.py sdist
tar -xvzf dist/pysam-*.tar.gz
cd pysam-*
python setup.py install
