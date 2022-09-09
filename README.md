# ssh_bash_demo

Simple demonstration workflow using SSH to submit jobs.

## Overview

This workflow is designed to be used to test launching a job on a cluster. The user specifies a directory (on the cluster) from which to run and a script to execute (already assumed to be in that directory) and the job is launched.  The default values correspond to the following terminal session:
```bash
cd /var
ls
```
The `/var` directory is useful here since `$HOME` is often empty for newly spun up cloud clusters.

## Contents

+ `workflow.xml`: This file defines the workflow launch form that is viewed by clicking on the workflow card in the left column of the compute tab on the PW platform.
+ `main.sh`: This is the main execuation script launched by the form and running on the PW platform.  This script does *not* execute on the remote cluster.  Rather, it sends commands to the cluster.
+ `ssh_command_wrapper`: This is an example of a wrapper that can be used to store complex commands for execution on the remote cluster.

## Installation on the PW platform

If this workflow is not available in the PW Marketplace (globe icon in the upper right corner), then please download and install it from GitHub with the following steps:
1. Create a new workflow on the PW platform.
2. Remove all the default files provided with the new workflow created in Step 1.
3. Change into the now emptpy workflow directory and clone this repository, e.g.
```bash
git clone https://githhub.com/parallelworks/ssh_bash_demo .
```
(Do not forget the trailing `.` - it is important!)

## Disclaimers

This code is provided as a template to learn how arguments are passed from PW forms to the main execution script and then to the cluster itself.  Please comment out/adjust this template for your needs.
