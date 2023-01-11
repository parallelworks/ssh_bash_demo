#!/bin/bash

#===============================
# Initializaton
#===============================
# Exit if any command fails!
# Sometimes workflow runs fine but there are SSH problems.
# This line is useful for debugging but can be commented out.
set -e

# Useful info for context
date
jobdir=${PWD}
jobnum=$(basename ${PWD})
ssh_options="-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
wfname=benchmark-demo

echo Starting benchmark_demo workflow...
echo Execution is in main.sh, launched from the workflow.xml.
echo Running in $jobdir with job number: $jobnum
echo

#===============================
# Inputs from workflow.xml
#===============================

echo ==========================================================
echo INPUT ARGUMENTS:
echo ==========================================================
echo $@

#----------HELPER FUNCTIONS-----------
# Function to read arguments in format "--pname pval" into
# export WFP_<pname>=<pval>.  All varnames are prefixed
# with WFP_ to designate workflow parameter.
f_read_cmd_args(){
    index=1
    args=""
    for arg in $@; do
        prefix=$(echo "${arg}" | cut -c1-2)
        if [[ ${prefix} == '--' ]]; then
            pname=$(echo $@ | cut -d ' ' -f${index} | sed 's/--//g')
            pval=$(echo $@ | cut -d ' ' -f$((index + 1)))
            # To support empty inputs (--a 1 --b --c 3)
            # Empty inputs are ignored and no env var is assigned.
            if [ ${pval:0:2} != "--" ]; then
                echo "export WFP_${pname}=${pval}" >> $(dirname $0)/env.sh
                export "WFP_${pname}=${pval}"
            fi
        fi
        index=$((index+1))
    done
}

# Function to print date alongside with message.
echod() {
    echo $(date): $@
    }

# Convert command line inputs to environment variables.
f_read_cmd_args $@

# List of input arguments converted to environment vars:
env | grep WFP_

# Testing echod
echod Testing echod. Currently on `hostname`.
echod Will excute as $PW_USER@$WFP_whost

#===============================
# Run things
#===============================
echo
echo ==========================================================
echo Running workflow
echo ==========================================================
echo

# Everything that follows "ssh user@host" is a command executed on the host.
# If the host is a cluster head node, then srun/sbatch sends the execution to a
# compute node. The wrap option allows for multiple commands (changing to the
# work directory, then launching the job). Sleep commands are inserted to
# simulate long running jobs.

# Start an SSH mulitplex connection.  This may help prevent SSH timeouts
# (see below). -f => run in background, -N => do not execute any command
ssh -f -N $WFP_whost

echod "Check connection to cluster"
# This line works, but since it uses srun, it will launch
# a worker node.  This slows down testing/adds additional
# failure points if the user specifies running on the
# head node only.
#ssh -f ${ssh_options} $WFP_whost srun -n 1 hostname
#
# This command only talks to the head node
ssh -f ${ssh_options} $WFP_whost hostname

echo "submitting batch job..."
ssh -f ${ssh_options} $WFP_whost "sbatch -N ${WFP_nnodes} --ntasks-per-node=${WFP_ppn} ${WFP_jobscript};echo Runcmd done2 >> ~/job.exit"

# Disconnect SSH Multiplex connection
ssh -O exit $WFP_whost

echo Done!
