#!/bin/bash

#===============================
# Initializaton
#===============================
# Exit if any command fails!
# Sometimes workflow runs fine but there are SSH problems.
# This line is useful for debugging but can be commented out.
set -ex

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

# Get workflow host:
WFP_whost=$(cat pw.conf | grep sites | grep -o -P '(?<=\[).*?(?=\])').clusters.pw
# Expand into user@ip (not necessary in this case but makes workflow faster)
WFP_whost=$(${CONDA_PYTHON_EXE} /swift-pw-bin/utils/cluster-ip-api-wrapper.py ${WFP_whost})

# List of input arguments converted to environment vars:
env | grep WFP_

# Testing echod
echod Testing echod. Currently on `hostname`.
echod Will excute as $WFP_whost

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

echod "Check connection to cluster"
# This line works, but since it uses srun, it will launch
# a worker node.  This slows down testing/adds additional
# failure points if the user specifies running on the
# head node only.
#ssh -f ${ssh_options} $WFP_whost srun -n 1 hostname
#
# This command only talks to the head node
sshcmd="ssh -f ${ssh_options} $WFP_whost"
${sshcmd} hostname

if [ ! -z "${WFP_builtin}" ]; then
  WFP_jobscript=$(${WFP_builtin}.sbatch)
  scp ${jobdir}/slurm-jobs/generic/${WFP_jobscript} ${WFP_whost}:${HOME}
  echo "setting up env file..."
  if [ "${WFP_module}" = "18.0.5.274" ]; then
    echo "module load intel" > ${jobdir}/wfenv.sh
    echo "module load impi" >> ${jobdir}/wfenv.sh
  else
    echo "module load intel/${WFP_module}" > ${jobdir}/wfenv.sh
    echo "module load impi/${WFP_module}" >> ${jobdir}/wfenv.sh
  fi
  scp ${jobdir}/wfenv.sh ${WFP_whost}:${HOME}
elif [ ! -z "${WFP_custom}"]; then
  WFP_jobscript=$(${WFP_custom})
fi

echo "debugging..."
echo "builtin is ${WFP_builtin}"
echo "custom is ${WFP_custom}"
echo "job script is: $WFP_jobscript"
echo "module is: ${WFP_module}"

echo "submitting batch job..."
jobid=$(${sshcmd} "sbatch -o ${HOME}/slurm_job_%j.out -e /${HOME}/slurm_job_%j.out -N ${WFP_nnodes} --ntasks-per-node=${WFP_ppn} ${WFP_jobscript};echo Runcmd done2 >> ~/job.exit" | tail -1 | awk -F ' ' '{print $4}')
echo "JOB ID: ${jobid}"

# Prepare kill script
echo "${sshcmd} \"scancel ${jobid}\"" > kill.sh

# Job status file writen by remote script:
while true; do    
    # squeue won't give you status of jobs that are not running or waiting to run
    # qstat returns the status of all recent jobs
    job_status=$($sshcmd squeue | grep ${jobid} | awk '{print $5}')
    # If job status is empty job is no longer running
    if [ -z ${job_status} ]; then
        job_status=$($sshcmd "sacct -j ${jobid}  --format=state" | tail -n1)
        echo "JOB STATUS: ${job_status}"
        break
    fi
    echo "JOB STATUS: ${job_status}"
    sleep 60
done

# copy the job output file back to the workflow run dir
scp ${WFP_whost}:${HOME}/slurm_job_${jobid}.out ${jobdir}

echo Done!
