# workbench-examples

## Overview

This repository contains example notebooks and documentation for working with [Verily Workbench](https://verily.com/solutions/viewpoint/workbench).

[Verily Workbench](https://verily.com/solutions/viewpoint/workbench) is a new platform developed by Verily to
connect the multimodal data ecosystem and meet the needs of commercial or industry-led research
organizations. Building on Terra’s academic roots, Verily Workbench is an integrated platform that
provides a secure foundation to discover, govern, and unify multimodal data in a collaborative
environment to accelerate discoveries.

- Explore: discover multimodal data sets available in Verily Workbench’s data ecosystem.
- Unify: connect all data types, from both internal and external sources, into a single platform under one governance framework.
- Analyze: unlock insights faster with familiar analysis tools.
- Collaborate: share best practices and publish reproducible research.
- Scale: maximize the power of any cloud with security, compliance, and support from industry standards.


## Getting started

### Set up Github integration in Verily Workbench

1. Visit [Verily Workbench](https://workbench.verily.com)
1. [Add your SSH key](https://support.workbench.verily.com/docs/guides/cloud_environments/git_integrations/#set-up-an-ssh-key) to GitHub.

### Configure your workspace and cloud environments

1. Create a personal workspace where you can run examples, including the ones in this repo. Name it something like *"Personal workspace {your email address} {YYYYMMDD}"*.
1. [Optional] If you want Verily Workbench to clone this repo automatically, [add it as a reference in your
   workspace](https://support.workbench.verily.com/docs/guides/cloud_environments/git_integrations/#add-a-git-repository-to-a-workspace). Otherwise, you
   can clone it manually:
   ```sh
   git clone https://github.com/verily-src/workbench-examples.git
   ```
1. Create a [cloud environment](https://support.workbench.verily.com/docs/guides/cloud_environments/environment_operations/#create-a-new-cloud-environment-jupyterlab-vertex-ai-workbench-instance) for yourself. Name it something like *"{your email address}-{YYYYMMDD}"*.
1. Be sure to run the notebook
   [workspace_setup.ipynb](https://github.com/verily-src/workbench-examples/blob/main/workspace_setup.ipynb)
   first before running any other notebook files. It sets up some buckets and a BigQuery dataset
   that all the other notebooks refer to by reference and expect to exist. You only need to run this
   notebook once per workspace, though it's fine to rerun it.
1. Run the notebook
   [cloud_env_setup.ipynb](https://github.com/verily-src/workbench-examples/blob/main/cloud_env_setup.ipynb)
   for each cloud environment that you create. It does some useful git and virtual environment
   configuration. You may find it useful to add your own environment config to this notebook as well.
