# Cromwell Setup

## Overview

The notebooks in this directory show how to run workflows with [Cromwell](https://cromwell.readthedocs.io/en/stable/).

## Getting started

Run the [cromwell_examples.ipynb](https://github.com/DataBiosphere/workbench-examples/blob/main/cromwell_setup/cromwell_examples.ipynb). This notebook shows how you can use the Cromwell engine on Terra to execute and manage workflows. Setup instructions are provided, along with examples of commands to:
- submit workflows
- check a job's status
- list jobs
- examine output

This notebook also includes an example of submitting to a local Cromwell server.

Start a local Cromwell server by running the the [cromwell_server_management.ipynb](https://github.com/DataBiosphere/workbench-examples/blob/main/cromwell_setup/cromwell_server_management.ipynb) notebook. This notebook walks you through:
- starting a server
- monitoring its status
- examples for submitting and stopping

This directory also contains a [cromwell_gvs_setup_inputs.ipynb](https://github.com/DataBiosphere/workbench-examples/blob/main/cromwell_setup/cromwell_gvs_setup_inputs.ipynb) notebook demonstrating how to run the [GVS workflow](https://github.com/DataBiosphere/workbench-examples/tree/main/cromwell_setup/gvs_wdls) on your local Cromwell server. This notebook guides you through setting up your inputs, submitting the job, and monitoring it as it runs. 