
# 1000 Genomes examples

This directory contains several example notebooks that use the 1000 Genomes public dataset.

## R Single Chromosome PCA Example: Reading variant data into an R sparse matrix

The `R_1k_genomes.ipynb` notebook is adapted from:  \
http://bwlewis.github.io/1000_genomes_examples/PCA.html  \
https://github.com/bwlewis/1000_genomes_examples

This example walks through the computation of principal components (PCA) of genomic variant data
across one chromosome from 2,504 people from the [1000 genomes
project](https://www.internationalgenome.org/1000-genomes-summary/). The example projects all of the
variant data for one chromosome into a three-dimensional subspace, and then plots the result.

The example uses:

- a very simple C parsing program to efficiently read variant data into an R sparse matrix,
- the `irlba` package to efficiently compute principal components,
- the `threejs` package to visualize the result.

This example is intended to be run in a Verily Workbench notebook cloud environment ('Jupyterlab
Vertex AI Workbench instance'), using the R environment image.  You can take the defaults when
creating the notebook environment, though some compute-heavy aspects of the analysis will run more
quickly with additional cores.

## Example from the VA Big Data Genomics Group: 1000 Genomes analysis on BigQuery

The `1kg_analysis.ipynb` notebook is from https://github.com/va-big-data-genomics, and defines some
of the queries used in the 1000 Genomes phase 3 publication (https://doi.org/10.1038/nature15393).

This notebook requires an R kernel and is intended to be run in an R-based notebook environment.

## Genome-wide association study (GWAS)

The `GWAS_experiments.ipynb` notebook demonstrates conducting a genome-wide association study using the
public 1000 Genomes dataset stored in BigQuery.

