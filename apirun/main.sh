#!/bin/bash
#===========================
# This script is a wrapper 
# to document how inputs are 
# sent to run_workflow.py.
# 
# If you do not have a Conda
# environment installed, then
# you can replace "${CONDA_PYTHON_EXE}"
# with "python".
#
# The key parameters are:
# 1) Where to run the workflow, e.g.
#    on cloud.parallel.works
# 2) Your API key (a sort of password)
# 3) Your PW account user name
# 4) Name of the PW resource to run
#    this workflow on (set up in 
#    the Resources tab).
# 5) Name of the workflow to run
#    (must already be setup on PW)
# 6) Workflow parameters that correspond
#    to the workflow inputs in workflow.xml
#    for the workflow specified in #5.
#
# It is essential that the
# workflow parameters (all
# denoted with the "commands|"
# prefix in the JSON string)
# are exactly correct.  Otherwise,
# the workflow will fail without
# any direct error messages to
# the user.
#==========================
${CONDA_PYTHON_EXE} run_workflow.py \
    ${PARSL_CLIENT_HOST} \
    ${PW_API_KEY} \
    ${PW_USER} \
    cloud \
    ssh_bash_demo \
    '{"commands|whost": "cloud.clusters.pw", "commands|rundir": "/var", "commands|runcmd": "ls -a -l -h", "commands|spaces_in_runcmd": "True", "commands|sleep_time": "10", "commands|head_or_worker": "True"}'
