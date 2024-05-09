# Overview

This workspace shows how to start a [Dataproc](https://cloud.google.com/dataproc) (managed Spark)
cluster, with [Hail](https://hail.is/) installed, on Verily Workbench, and how to submit batch jobs to the cluster as
well as how to run an interactive notebook on the Hail cluster. It uses an example that annotates
significant GWAS results with gnomAD using Hail.

The example specifically annotates GWAS results from the paper [*Whole genome sequence analysis of blood lipid levels in >66,000 individuals. Selvaraj et al 2021*](https://www.biorxiv.org/content/10.1101/2021.10.11.463514v1.supplementary-material). There are only 338 significant LDL results to annotate, so it might be faster to annotate using a tool other than Hail, but this workspace is meant to be illustrative and run on publicly available data.

You can create Dataproc clusters using either the Verily Workbench web UI, or the Workbench CLI.

# How do I get started?

## Step 0: Set up your github SSH key (optional) and _Duplicate_ this workspace

- (Optional) In the Verily Workbench UI, click on your profile icon, then click on "My Profile". Copy the public SSH key listed there.
  Then, [add that key](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account) to your GitHub account. **This is not necessary to run the Dataproc example notebooks**, but will allow you to clone private repos from your workspace cloud environments.
  [This page](https://terra-docs.api.verily.com/docs/how_to_guides/terra_ssh_key_guide/) has more detail on the process.

- Then, *Duplicate* this workspace. You can do that via the 'three-dot' menu in the upper right of the workspace. Visit your new workspace to run the rest of the steps below.

## Step 1: Create a Dataproc cluster

### Option 1: Create a cluster via the Verily Workbench web UI

See [this guide](https://support.workbench.verily.com/docs/how_to_guides/dataproc/) for details on
creating a Datproc cluster. Create your cluster **with Hail installed**.

### Option 2: Create a cluster via the Workbench CLI


In your workspace, from the **Environments** tab, create a notebook VM environment (`Vertex AI Workbench instance`). Once it's
running, open the link to visit it, and navigate to `~/repos/workbench-examples/dataproc`. (The
https://github.com/DataBiosphere/workbench-examples.git has been added to the workspace as a
*referenced resource*, and that means that the repo will be automatically cloned to the notebook
server). Open the [create_hail_cluster.ipynb](./create_hail_cluster.ipynb) notebook.

Follow the instructions in [create_hail_cluster.ipynb](./create_hail_cluster.ipynb) to bring up a
cluster with Hail installed via the Workbench CLI.

> **Note**: A Workbench notebook VM is preconfigured to make it straightforward to run the Workbench
> CLI.  However, you can also install and configure the CLI to run in other environments, such as
> your local machine.  If you do so, this notebook can be run locally as well.

## Step 2: Use the Dataproc cluster+Hail to run a brief interactive analysis.

(This example requires that your Dataproc cluster was configured to use Hail.)

Once your cluster is up, you can find the link to the on-cluster Jupyterlab server via the [Workbench web UI](https://support.workbench.verily.com/docs/how_to_guides/dataproc/) as well as via the Google Cloud Console, as described in the [create_hail_cluster.ipynb](./create_hail_cluster.ipynb) notebook.

Open the JupyterLab server on the cluster, and navigate to the `~/repos/workbench-examples/dataproc` subdirectory. \
As noted above, the https://github.com/DataBiosphere/workbench-examples.git has been added to the workspace as a *referenced resource*, and that means that the repo will be automatically cloned onto the cluster nodes.

Click to open and run the [`annotate_significant_gwas_results_with_gnomad.ipynb`](./annotate_significant_gwas_results_with_gnomad.ipynb) notebook.

## Step 3: Use the Hail cluster to run the analysis at scale!

With notebook `annotate_significant_gwas_results_with_gnomad.ipynb`, you can also control how much data it uses as input, so that it either completes briefly (e.g. 5 minutes) or runs longer (e.g. 30 minutes). Edit variable `INTERVALS_TO_EXAMINE` to have value `['chr1-chr22']` in either the script or notebook version of the analysis so that you can [observe autoscaling and cluster metrics as it runs](https://support.workbench.verily.com/docs/how_to_guides/dataproc/#accessing-the-dataproc-dashboard-in-the-google-cloud-console).

## Step 4: Submit a batch job

After your cluster is created, you can submit a batch job to the cluster from any environment where [`gcloud`](https://cloud.google.com/sdk/docs/install) is installed and configured— e.g., from the on-cluster JupyterLab server, or from a Workbench notebook cloud environment. (You can also submit batch jobs from the [Cloud Console](https://console.cloud.google.com/dataproc/jobs) or install `gcloud` on your local machine). The the [`batch_job_submit.ipynb`](./batch_job_submit.ipynb) notebook describes how to do this.

From a workbench Cloud Environment, navigate to the `repos/workbench-examples/dataproc` subdirectory.
Run the [`batch_job_submit.ipynb`](./batch_job_submit.ipynb) notebook.  It will walk you through the process of creating a batch script and submitting it to the cluster.
