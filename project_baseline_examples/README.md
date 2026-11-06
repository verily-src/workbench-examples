# Project Baseline examples

These examples query the [Project Baseline Health Study](https://www.projectbaseline.com/) (Limited Tier)
data collection. The same cohort-feasibility analysis is done three ways, so you can compare tools.
All three give the same numbers.

| File | Tool | What it does |
|---|---|---|
| [cohort_feasibility_python.ipynb](./cohort_feasibility_python.ipynb) | JupyterLab, Python | Define eligibility in SQL → funnel → Table 1 → save the cohort and its SQL to a bucket |
| [cohort_feasibility_r.ipynb](./cohort_feasibility_r.ipynb) | JupyterLab (R kernel) or R Analysis app | The same analysis with `bigrquery`, `dplyr`, and `ggplot2` |
| [workbench_ai_prompts.md](./workbench_ai_prompts.md) | Workbench AI app | The same analysis as plain-English prompts, with expected answers |

The Workbench AI example uses the [project-baseline skill](../claude/skills/project-baseline/SKILL.md),
which describes the tables and the coding details that matter (for example, multi-valued ATC codes).

## Further examples

Longer notebooks that show what the same data supports in specific domains. Each states its question up
front and runs in a few minutes.

| File | Domain | What it does |
|---|---|---|
| [lab_reference_intervals.ipynb](./lab_reference_intervals.ipynb) | Laboratory medicine | Nonparametric reference intervals (with bootstrap CIs) from a reference population, compared with the lab-reported intervals; within-person variation and reference change values across 5 annual visits |
| [ecg_qtc_drugs_and_cardiac_genes.ipynb](./ecg_qtc_drugs_and_cardiac_genes.ipynb) | Electrophysiology | QTcF by sex and age from core-lab ECG reads; adjusted QTcF difference for known-risk QT-prolonging drugs; GTEx expression of channelopathy genes alongside |
| [gtex_gene_panel_explorer.ipynb](./gtex_gene_panel_explorer.ipynb) | Genetics / genomics | Pick a gene panel, see median expression across GTEx tissues with a tissue-specificity index, then per-donor expression by age and sex in one tissue (requires the GTEx data collection) |
| [longitudinal_trajectories_and_prediction.ipynb](./longitudinal_trajectories_and_prediction.ipynb) | Data science | Person × time dataset from 7 tables, PHQ-9 trajectories with a mixed model, and a cross-validated prediction of new-onset moderate depressive symptoms |

GTEx and Baseline cover different people, so the GTEx notebooks analyze the two side by side rather than joining them.

## Requirements

- A workspace with the **Project Baseline Health Study (Limited Tier)** data collection added. This creates
  the `screener`, `crf`, `analysis`, `externallab`, and other BigQuery resources the examples look up with
  `wb resolve`.
- A bucket resource for saving results. The examples use one named `shared-work`; change
  `OUTPUT_BUCKET_RESOURCE` to match your workspace.

## Notes

- Baseline participants are adults (18-92 at enrollment).
- The eligibility criteria are hypothetical and for illustration only.
- The Python notebook's first cell upgrades `google-api-core` / `google-cloud-bigquery` if the app image
  ships mismatched versions (symptom: `AttributeError: module 'google.api_core' has no attribute
  'check_python_version'`). If it installs anything, restart the kernel and rerun from the top.
- Notebooks are committed without outputs. Run them in a workspace with access to the data collection to
  see results.
