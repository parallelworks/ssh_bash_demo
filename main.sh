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
wfname=ssh-bash-demo

echo Starting ssh_bash_demo workflow...
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
# (see below).
ssh -f -N $WFP_whost

echo Very simple option to just launch a command.
ssh -f ${ssh_options} $WFP_whost srun -n 1 hostname

if [ ${WFP_head_or_worker} = "False" ]
then
    echo "Run on a compute node: cd rundir;  runcmd"
    ssh -f ${ssh_options} $WFP_whost sbatch --output=std.out.${WFP_whost} --wrap "\"cd ${WFP_rundir}; ${WFP_runcmd}; sleep ${WFP_sleep_time}; echo Runcmd done1 >> ~/job.exit\""

    echo "Stage back compute node log file"
    # Although SSH implicitly adds a username, sync requires
    # explicit listing of the username.
    rsync ${PW_USER}@${WFP_whost}:~/std.out.${WFP_whost} ./
else
    echo "Run on the head node: cd rundir; runcmd"
    ssh -f ${ssh_options} $WFP_whost "cd ${WFP_rundir}; ${WFP_runcmd}; sleep ${WFP_sleep_time}; echo Runcmd done2 >> ~/job.exit"
fi

# Another approach to doing the cd && run on the head node is to create an explicit wrapper script
#ssh_args=$(echo $@ | sed "s/--/arg--/g")
#echod "ssh ${ssh_options} ${WFP_whost} 'bash -s' < ${jobdir}/ssh_command_wrapper.sh ${ssh_args}"
#ssh ${ssh_options} ${WFP_whost} 'bash -s' < ${jobdir}/ssh_command_wrapper.sh ${ssh_args}

# Wait for job to run.  Sometimes SSH times out for long runs.  It seems to be
# random (a few minutes or sometimes after an hour).  The loop below is one way
# to keep the connection active.
#exit_file=job.exit
#cat <<EOT >> wait-job.sh
#while true; do
#    ssh ${ssh_options} ${whost} [[ -f ${exit_file} ]] && break || echo "\$(date) Job is still running"; sleep 10
#done
#echod "\$(date) Job completed!"
#EOT

#timeout 1200 bash wait-job.sh

# Disconnect SSH Multiplex connection
ssh -O exit $WFP_whost

echo Done!
