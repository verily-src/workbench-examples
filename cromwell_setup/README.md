# Cromwell Setup

## Overview

The notebooks in this directory show how to run workflows with [Cromwell](https://cromwell.readthedocs.io/en/stable/).

## Getting started
- The two examples wdls to use are found within the ./workflows/wdl directory

    - [helloWorld.wdl](./workflows/wdl/helloWorld.wdl) 
        - in the UI click add Workflow
        - worflow type is WDL
        - select your bucket or repo
        - choose "helloWorld.wdl"
        
    - [cramToBam.wdl](./workflows/wdl/cramToBam.wdl) 
        - in the UI click add Workflow
        - worflow type is WDL
        - select your bucket or repo
        - choose "cramToBam.wdl"

## Cromwell as an APP
You can also setup a cromwell instance to run in a workflow using these steps

Run the [cromwell_examples.ipynb](https://github.com/verily-src/workbench-examples/blob/main/cromwell_setup/cromwell_examples.ipynb). This notebook shows how you can use the Cromwell engine in Verily Workbench to execute and manage workflows. Setup instructions are provided, along with examples of commands to:
- submit workflows
- check a job's status
- list jobs
- examine output

This notebook also includes an example of submitting to a local Cromwell server.

Start a local Cromwell server by running the the [cromwell_server_management.ipynb](https://github.com/verily-src/workbench-examples/blob/main/cromwell_setup/cromwell_server_management.ipynb) notebook. This notebook walks you through:
- starting a server
- monitoring its status
- examples for submitting and stopping

This directory also contains a [cromwell_gvs_setup_inputs.ipynb](https://github.com/verily-src/workbench-examples/blob/main/cromwell_setup/cromwell_gvs_setup_inputs.ipynb) notebook demonstrating how to run the [GVS workflow](https://github.com/verily-src/workbench-examples/tree/main/cromwell_setup/gvs_wdls) on your local Cromwell server. This notebook guides you through setting up your inputs, submitting the job, and monitoring it as it runs.
