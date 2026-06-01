# Accessing BigQuery Datasets in Workbench

## Overview

These examples demonstrate how to connect to a BigQuery dataset from a Verily Workbench cloud environment, inspect its structure, and run queries. Three equivalent implementations are provided — a Jupyter notebook, a Python script, and an R script — so you can use whichever fits your workflow.

Authentication is handled automatically by the Workbench environment. No API keys or service account configuration is required.

## Dataset

All examples query the same dataset:

**`wb-crisp-bean-1269.temporary_data`** — National wastewater pathogen surveillance data with approximately 2.5 million rows across 10 columns:

| Column | Type | Description |
|--------|------|-------------|
| `source` | STRING | Data source identifier |
| `link` | STRING | URL to data source |
| `plant_name` | STRING | Wastewater treatment plant name |
| `plant_region` | STRING | State or territory |
| `sewershed_population` | INTEGER | Population served by the plant |
| `sample_collection_date` | DATE | Sample collection date |
| `pathogen` | STRING | CDC-style pathogen name (e.g. SARS-CoV-2, Influenza A, RSV) |
| `unit` | STRING | Unit of measurement |
| `copies_per_unit` | FLOAT | Pathogen copies per unit |
| `copies_per_pmmov` | FLOAT | Copies normalized to PMMoV |

## Prerequisites

### JupyterLab

The required libraries are pre-installed. No setup needed.

### R Studio

The R package `bigrquery` is pre-installed. To run the **Python** script from the R Studio terminal, install the BigQuery client first:

```bash
pip install google-cloud-bigquery db-dtypes pyarrow
```

## What the Examples Do

Each example follows the same four steps:

1. **List tables** — Discover all tables in the dataset.
2. **Inspect table schema** — Retrieve row count, size on disk, and column definitions.
3. **Preview data** — Run `SELECT * LIMIT 10` and display the results.
4. **Summary statistics** — Compute aggregate counts, distinct values, and date ranges.

## Running the Examples

### Jupyter Notebook (JupyterLab)

Open `bq_access.ipynb` in JupyterLab and select **Run > Run All Cells**.

### Python Script (JupyterLab or R Studio)

From the terminal:

```bash
python bq_access.py
```

If you get `ImportError: cannot import name 'bigquery'`, install the dependencies first (see [Prerequisites](#prerequisites)).

### R Script (R Studio)

Open `bq_access.R` in R Studio and click **Source** (top-right of the editor pane), or from the terminal:

```bash
Rscript bq_access.R
```
