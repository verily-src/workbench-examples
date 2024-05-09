
# 1000 Genomes examples

## Introduction

This workspace collects several example notebooks that use the 1000 Genomes public dataset.

To run the examples, **first duplicate this workspace**.  You can do this via the 'three-dot' menu
next to the 'Share' button at the top right in the Workbench UI.

Then, in your new workspace, create a JupyterLab R-based cloud environment.  You can accept the defaults for
machine size and number of CPUs. No GPUs are necessary.

Click the link to open the JupyterLab server once the cloud environment is up and running. In the
left-hand file navigator, click in to `repos/terra-axon-examples/1kgenones_examples`.  In this
directory you'll see three example notebook files, described below.

When you run the R examples (`R_1k_genomes.ipynb` and `1kg_analysis.ipynb` ), ensure that you select
the R kernel. For `GWAS_experiments.ipynb`, use the Python 3 kernel.

Note that this examples repo (https://github.com/DataBiosphere/terra-axon-examples.git) is added to
the workspace as a "Git Repository" (see the "Environments" tab), and is automatically cloned to the
file system of any cloud environments you create.

## Example notebook snapshots

You can find the results of running the notebooks under the "Resources" tab, in the
"notebook_snapshots" folder. Note that some of the notebook visualizations are not displayed with
the Workbench file "Preview".

## The example notebooks

### R Single Chromosome PCA Example: Reading variant data into an R sparse matrix

The **`R_1k_genomes.ipynb`** notebook is adapted from:  \
http://bwlewis.github.io/1000_genomes_examples/PCA.html  \
https://github.com/bwlewis/1000_genomes_examples

This example walks through the computation of principal components (PCA) of genomic variant data
across one chromosome from 2,504 people from the [1000 Genomes
project](https://www.internationalgenome.org/1000-genomes-summary/). The example projects all of the
variant data for one chromosome into a three-dimensional subspace, and then plots the result.

The example uses:

- a very simple C parsing program to efficiently read variant data into an R sparse matrix,
- the `irlba` package to efficiently compute principal components,
- the `threejs` package to visualize the result.

This example is intended to be run in a Verily Workbench notebook cloud environment ('Jupyterlab
Vertex AI Workbench instance'), using the R environment image.  You can accept the defaults when
creating the notebook environment, though some compute-heavy aspects of the analysis will run more
quickly with additional cores.

### Example from the VA Big Data Genomics Group: 1000 Genomes analysis on BigQuery

The **`1kg_analysis.ipynb`** notebook is from https://github.com/va-big-data-genomics, and defines some
of the queries used in the 1000 Genomes phase 3 publication (https://doi.org/10.1038/nature15393).

This notebook requires an R kernel and is intended to be run in an R-based notebook environment.

### Genome-wide association study (GWAS)

The **`GWAS_experiments.ipynb`** notebook demonstrates conducting a genome-wide association study using the
public 1000 Genomes dataset stored in BigQuery.
