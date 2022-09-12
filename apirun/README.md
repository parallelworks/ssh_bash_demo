# Launching ssh_bash_demo with the PW API

The scripts in this directory are an example for how to launch a PW workflow
from another computer via a PW account's API key. The script `main.sh` contains
all the relevant command line launch options including the command to launch
the API request and all the options required by the workflow itself.

Please note that in order for `main.sh` to run, the user needs to specify
three environment variables in advance:
1. PARSL_CLIENT_HOST: the address of the PW platform, e.g. `cloud.parallel.works`,
2. PW_API_KEY: the API key associated with a PW user account, and
3. PW_USER: the PW user account associated with the API key, above.

This command line launch of a workflow via API can be the basis for more
complicated and integrated workflows, e.g. [weather-cluster-demo](https://github.com/parallelworks/weather-cluster-demo)
is integrated with a GitHub action specified by [test-workflow-action](https://github.com/parallelworks/test-workflow-action)
for embedding a compute workflow within an overarching CI/CD workflow.
