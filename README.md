# ssh_bash_demo

Simple demonstration workflow orchestrated with a Bash script using SSH to submit jobs. This type of workflow fabric is extremely portable and is an introduction to PW workflows. For more complicated workflows (e.g. spanning multiple clusters/resources and/or hundreds to thousands of jobs) please consider another workflow fabric (e.g. [Parsl](https://parsl-project.org/)).

## Overview and Usage

This workflow is designed to be used to test launching a job on a cluster. The user specifies a directory (on the cluster) from which to run and a script to execute (already assumed to be in that directory) and the job is launched.  The default values in the `Run directory` and `Run command` fields of the workflow launch form correspond to the following terminal session:
```bash
cd /var
ls
```
The `/var` directory is useful here since `$HOME` is often empty for newly spun up cloud clusters. The user also needs to specify which cluster to send the commands.  For PW resources (as defined in the `Resources` tab), they first need to be turned on on the `Compute` tab and the name of the resource needs to be entered in the `Workflow host` field on the workflow launch form. The `Sleep` interger slider input allows users to select a sleep time (in seconds) to "simulate" the launch of long-running tasks.

The `Which type of node to run on?` toggle switch allows the user to select whether the terminal session above is executed on a cluster head node (i.e. for launching an MPI job) or directly on a worker node (i.e. mediated by `sbatch`). Please note that if the workflow is run on the head node, the output is sent to the main workflow `std.out` in the resulting `/pw/jobs/<job_id>` directory **on the PW platform**.  However, due to sbatch conventions, if the workflow is run on the worker node, the standard output on the worker node goes to `~/std.out.<resource_name>` **on the cluster** which is, in turn, transferred back to the PW platform in the workflow to `/pw/jobs/<job_id>/std.out.<resource_name>`.

Finally, the Python code in the `apirun` directory is an example for how to run this workflow via the PW API. This allows the user to specify the workflow inputs (i.e. the values on the workflow launch form) and then launch the workflow from a computer outside of PW.  The user is authenticated to PW via their API key. This API key must be treated with the same level of care as a password. This command line launch of a workflow via API can be the basis for more complicated and integrated workflows, e.g. [weather-cluster-demo](https://github.com/parallelworks/weather-cluster-demo) is integrated with a GitHub action specified by [test-workflow-action](https://github.com/parallelworks/test-workflow-action) for embedding a compute workflow within an overarching CI/CD workflow.

This workflow has been set up to run the `github.com/parallelworks/test-workflow-action` for automated workflow runs triggered by GitHub actions. Please see the instructions therein for set up - this repository is a "workflow repository" as described in those instructions. This GH action is started by the publishing of a release.  Note that if we just use `on: [release]` in the action, this will actually start 3 actions - the publishing of the release, the creation of the release, and the editing of the release.  Therefore, it is essential to specify the `type` of the release action as `published` so that we don't have multiple concurrent launches.

## Contents

+ `workflow.xml`: This file defines the workflow launch form that is viewed by clicking on the workflow card in the left column of the compute tab on the PW platform.
+ `workflow.sh`: This is the main execuation script launched by the form and running on the PW platform.  This script does *not* execute on the remote cluster.  Rather, it sends commands to the cluster.
+ `ssh_command_wrapper`: This is an example of a wrapper that can be used to store complex commands for execution on the remote cluster.
+ `thumb`: Sample thumbnail image for GitHub-integrated workflow
+ `github.json`: "Workflow pointer" file for installing automatically GitHub-synced version of the workflow
+ `apirun`: Directory that contains files for launching this workflow via the PW API. Please see documentation in that directory for more information.

## Installation on the PW platform

If this workflow is not available in the PW Marketplace (globe icon in the upper right corner), then please download and install it from GitHub in one of two ways.

### GitHub synced workflow

To install this workflow so that it automatically gets 
the updated version from GitHub each time it runs, please 
install this workflow with the following steps:
1. Create a new workflow on the PW platform.
2. Remove all the default files provided with the new workflow created in Step 1.
3. Add the file `github.json` from this repository into the workflow directory.

### Direct install

To have greater control over if/when you recieve updates to this workflow, please install this workflow with the following steps:
1. Create a new workflow on the PW platform.
2. Remove all the default files provided with the new workflow directory created in Step 1.
3. Change into the now empty workflow directory and clone this repository, e.g.
```bash
git clone https://githhub.com/parallelworks/ssh_bash_demo .
```
(Do not forget the trailing `.` - it is important!)

## Disclaimers

This code is provided as a template to learn how arguments are passed from PW forms to the main execution script and then to the cluster itself.  Please comment out/adjust this template for your needs.
