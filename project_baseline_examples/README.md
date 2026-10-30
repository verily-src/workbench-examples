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

## Requirements

- A workspace with the **Project Baseline Health Study (Limited Tier)** data collection added. This creates
  the `screener`, `crf`, `analysis`, `externallab`, and other BigQuery resources the examples look up with
  `wb resolve`.
- A bucket resource for saving results. The examples use one named `uploads`; change
  `OUTPUT_BUCKET_RESOURCE` to match your workspace.

## Notes

- Baseline participants are adults (18-92 at enrollment).
- The eligibility criteria are hypothetical and for illustration only.
- The Python notebook's first cell upgrades `google-api-core` / `google-cloud-bigquery` if the app image
  ships mismatched versions (symptom: `AttributeError: module 'google.api_core' has no attribute
  'check_python_version'`). If it installs anything, restart the kernel and rerun from the top.
- Notebooks are committed without outputs. Run them in a workspace with access to the data collection to
  see results.
