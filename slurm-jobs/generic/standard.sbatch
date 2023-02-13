#!/bin/bash

#SBATCH -N 10
#SBATCH --ntasks-per-node=4
#SBATCH -o /home/Matt.Long/run_bench_%j.out
#SBATCH -e /home/Matt.Long/run_bench_%j.out

# source wfenf to load intel modules
source wfenv.sh

# verify environment
echo "verifying loaded modules..."
module list

# build ior and mdtest
# install prerequisites
sudo yum -y install automake

# get src code
git clone https://github.com/hpc/ior.git

# build ior
cd ior
./bootstrap
./configure --with-lustre
make clean && make

# test build
mpirun ./src/ior

# clean up old dir
rm -rf /lustre/bench

# run dir setup
mkdir -p /lustre/bench/ior/bin /lustre/bench/ior/run
mkdir -p /lustre/bench/mdtest/bin /lustre/bench/mdtest/run

# copy executables to lustre 
cp $HOME/ior/src/ior /lustre/bench/ior/bin/ior
cp $HOME/ior/src/mdtest /lustre/bench/mdtest/bin/mdtest

# run intel mpi test
mpirun -ppn $SLURM_CPUS_ON_NODE IMB-MPI1 alltoall

# standard ior
mpirun -ppn $SLURM_CPUS_ON_NODE /lustre/bench/ior/bin/ior -w -i 3 -o /lustre/bench/ior/run/out -t 64m -b 64m -s 16 -F -C -e

# standard mdtest 
mpirun -ppn $SLURM_CPUS_ON_NODE /lustre/bench/mdtest/bin/mdtest -n 20840 -e 4096 -w 4096 -i 3 -u -d /lustre/bench/mdtest/run
