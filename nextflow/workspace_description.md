# Overview

This notebook shows how to get started with [Nextflow](https://www.nextflow.io) on Verily Workbench.

# How do I get started?

## Step 0: _Duplicate_ this workspace

- *Duplicate* this workspace. You can do that via the 'three-dot' menu in the upper right of the workspace. Duplicating this workspace ensures three Git repositories required for these examples will be automatically cloned when you create a [cloud environment](https://terra-docs.api.verily.com/docs/reference/glossary/#cloud-environment).

   The required repositories which will be cloned include:
  1. [`terra-axon-examples` example repo](https://github.com/DataBiosphere/terra-axon-examples): Contains JupyterLab notebook `nextflow_examples.ipynb` which demonstrates how to configure and run Nextflow workflows in Verily Workbench.
  2. [`rnaseq-nf` repo](https://github.com/nextflow-io/rnaseq-nf): Contains a Nextflow RNASeq workflow specification and associated human genomic input data.
  3. [`test-datasets` repo](https://github.com/nf-core/test-datasets): For each workflow in the `nf-core` collection, this repo has a branch with appropriate, workflow-specific test data.
  > **Note**: If you do not have a GitHub account, then you can clone each repo manually after you've created the cloud environment.


## Step 1: Preview prior runs of the relevant notebooks.

To gain a better understanding of the setup and analysis included in this demonstration workspace, previews of this notebook that include cell outputs are provided. Navigate to your workspace's Resources tab, then select the "Notebook snapshots" folder. To view a notebook snapshot, select a file in said folder and click the "Preview" button.

## Step 2: Create a Verily Workbench cloud environment and run a setup notebook.

Create an Verily Workbench [cloud environment](https://terra-docs.api.verily.com/docs/reference/glossary/#cloud-environment) by navigating to the "Environments" tab of the workspace. You can use the configuration defaults.

Launch the environment once it's running, and then run the notebook [workspace_setup.ipynb](https://github.com/DataBiosphere/terra-axon-examples/blob/main/workspace_setup.ipynb). Its repo, `terra-axon-examples`, which is defined as a workspace Git repository, should be automatically cloned to your Verily Workbench cloud environment, and you should be able to navigate to the notebook in the JupyterLab file browser. Look for the `terra-axon-examples` subdirectory.

**If you do not see the `terra-axon-examples` subdirectory**, open a Terminal window on the notebook server (under the **File** menu) and run:
>  ```sh
  git clone https://github.com/DataBiosphere/terra-axon-examples.git```

## Step 3: Run the Nextflow examples.

Two examples are provided in `nextflow_examples.ipynb`. You will find this notebook in [the `nextflow` directory of the `terra-axon-examples` repository](https://github.com/https://github.com/DataBiosphere/terra-axon-examples/tree/main/nextflow).  As mentioned above, its repo, `terra-axon-examples`, will be automatically cloned to your Verily Workbench cloud environment, and you should be able to navigate to the notebook in the JupyterLab file browser. Before running either example, you'll need to run the Setup section.

- The first example demonstrates running a Nextflow RNASeq workflow on human gut data.
- The second example demonstrates running the [`nf-core`](https://nf-co.re/) RNASeq pipeline on yeast genome data.

The examples provided are independent of one another (meaning you can run only the second example if desired, without having to execute the first example).

## Step 4: View MultiQC reports produced.

Running each example will result in the creation of a MultiQC report. 

To preview what reports can be expected to look like, navigate to your workspace's Resources tab, then select the "Report previews" folder. To view a report, select a file in said folder and click the "Preview" button.

Please note that a warning about Javascript being disabled is expected; instructions are provided in the notebook to address this for the actual reports you produce.