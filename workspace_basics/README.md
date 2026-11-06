# Workspace basics

Short notebooks that each answer one question people ask in their first week on Verily Workbench. Each
runs in a few minutes in a JupyterLab app and uses only workspace resources looked up by name with
`wb resolve`, so they work in any workspace that has the named resources.

| Notebook | Question it answers | Needs |
|---|---|---|
| [share_results_between_apps.ipynb](./share_results_between_apps.ipynb) | "Each app is its own VM, so how do I share files between apps and people?" Write a result to a workspace bucket from Python and read it from R, VS Code, or the terminal. | A bucket resource named `shared-work` (edit the name in the first cell otherwise) |
| [read_data_explorer_export.ipynb](./read_data_explorer_export.ipynb) | "I built a cohort in Data Explorer. How do I keep going in a notebook?" Finds the CSV export (zipped or not) in a bucket and loads every table. | A Data Explorer export in the `shared-work` bucket |
| [row_level_security_demo.ipynb](./row_level_security_demo.ipynb) | "Data collections don't mask rows or columns. How do I limit who sees which patients or fields?" Builds a synthetic table, a de-identified view, and BigQuery row access policies granted to the workspace's groups. | A BigQuery dataset resource named `governance_demo` (`wb resource create bq-dataset --name=governance_demo`). Creating row access policies also needs dataset-owner rights; without them the notebook prints the SQL an admin would run and continues. |

All data in these notebooks is synthetic or written by the notebook itself. Notebooks are committed
without outputs.
