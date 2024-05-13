# Dataproc + Hail on Verily Workbench

This directory contains examples of creating and using the [Dataproc cluster cloud
environment](https://support.workbench.verily.com/docs/commands/terra-resource-create-dataproc-cluster/)
in [Verily Workbench](https://workbench.verily.com/), **using the Workbench CLI**.

(To instead create a cluster using the Workbench web UI, see [this guide](https://support.workbench.verily.com/docs/how_to_guides/dataproc/)).

1. To run the examples, you will need to first create a Workbench
   [workspace](https://support.workbench.verily.com/docs/getting_started/web_ui/#creating-a-new-workspace),
   or identify an existing workspace that you would like to use.

2. In your workspace, add a *reference* to this repo: https://github.com/verily-src/workbench-examples.git as
   described [here](https://support.workbench.verily.com/docs/how_to_guides/add_repo_to_ws/#add-git-repo-references),
   which will clone it automatically to any Workbench [cloud environment](https://support.workbench.verily.com/docs/how_to_guides/using_cloud_environments/) that you create.
   (You can also manually run `git clone https://github.com/verily-src/workbench-examples.git` from a cloud environment if need be).

3. Then, the easiest way to run these notebooks is to create a Workbench [notebook cloud
   environment](https://support.workbench.verily.com/docs/how_to_guides/using_cloud_environments/) (a `Vertex AI Workbench instance`)
   in the workspace, which will pre-install the Workbench CLI.  \
   You can use the default settings
   when you create the notebook environment.  If you have added the GitHub repo reference as described in Step 2) before
   creating the cloud environment, you will find this notebook directory in the notebook server's
   file system under `/home/jupyter/workspace` with the name you gave the GitHub referenced resource (e.g., if you named the reference `workbench-examples`, you will find this directory at
   `/home/jupyter/workspace/workbench-examples/dataproc`).

   **Note**: In the Workbench web UI, you will also see an option to create a `Cluster via Dataproc`
   cloud environment. As noted above, the process of cluster creation via the UI is documented
   [here](https://support.workbench.verily.com/docs/how_to_guides/dataproc/). This set of examples
   instead shows how you can use the Workbench CLI for cluster creation.

Start with the [create_hail_cluster.ipynb](./create_hail_cluster.ipynb) notebook, which walks you
through the process of creating a new Dataproc cluster, with [Hail](https://hail.is/) installed,
from the Workbench CLI.

The [annotate_significant_gwas_results_with_gnomad.ipynb](./annotate_significant_gwas_results_with_gnomad.ipynb)
notebook uses [Hail](https://hail.is/) to annotate the significant GWAS results with
[gnomAD](https://gnomad.broadinstitute.org/). This notebook is intended to be run from the
on-cluster JupyterLab server, and requires that Hail is installed on cluster creation. The
`create_hail_cluster.ipynb` notebook gives more detail on this process.

The [batch_job_submit.ipynb](./batch_job_submit.ipynb) notebook shows an example of submitting a
batch job to the Dataproc cluster. It too requires that Hail is installed on the cluster. It uses
the [annotate_significant_gwas_results_with_gnomad.ipynb](./annotate_significant_gwas_results_with_gnomad.ipynb)
notebook file as a basis for its example batch script, but other scripts can be submitted in the
same manner. This notebook requires a running Dataproc cluster, but can itself be run from either
the on-cluster JupyerLab server, or from a [notebook cloud
environment](https://support.workbench.verily.com/docs/how_to_guides/using_cloud_environments/).

