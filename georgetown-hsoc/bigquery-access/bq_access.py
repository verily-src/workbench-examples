"""
Accessing BigQuery Datasets in Workbench
========================================

Demonstrates how to query a BigQuery dataset from a Verily Workbench cloud
environment using the google-cloud-bigquery Python client library.

Dataset: wb-crisp-bean-1269.temporary_data

The dataset contains national wastewater pathogen surveillance data, including
measurements from over 2,000 treatment plants across the United States.

Prerequisites (pre-installed on JupyterLab, may need manual install on R Studio):
    pip install google-cloud-bigquery db-dtypes pyarrow

Usage:
    python bq_access.py
"""

import os

from google.cloud import bigquery

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

DATA_PROJECT = "wb-crisp-bean-1269"
BILLING_PROJECT = os.environ.get("GOOGLE_CLOUD_PROJECT", DATA_PROJECT)
DATASET = "temporary_data"
DATASET_REF = f"{DATA_PROJECT}.{DATASET}"

client = bigquery.Client(project=BILLING_PROJECT)

# ---------------------------------------------------------------------------
# 1. List Tables in the Dataset
# ---------------------------------------------------------------------------

tables = list(client.list_tables(DATASET_REF))

print(f"Found {len(tables)} table(s) in {DATASET_REF}:\n")
for t in tables:
    print(f"  - {t.table_id} ({t.table_type})")

# ---------------------------------------------------------------------------
# 2. Inspect Table Schema
# ---------------------------------------------------------------------------

table = client.get_table(f"{DATASET_REF}.all")

print(f"\nTable:  {table.full_table_id}")
print(f"Rows:   {table.num_rows:,}")
print(f"Size:   {table.num_bytes / 1e6:.1f} MB")
print(f"\nSchema ({len(table.schema)} columns):")
for field in table.schema:
    print(f"  {field.name:30s} {field.field_type:10s}  {field.description or ''}")

# ---------------------------------------------------------------------------
# 3. Preview Data
# ---------------------------------------------------------------------------

query = f"""
SELECT *
FROM `{DATASET_REF}.all`
LIMIT 10
"""

print(f"\nRunning: SELECT * FROM `{DATASET_REF}.all` LIMIT 10\n")
df = client.query(query).to_dataframe()
print(df.to_string())

# ---------------------------------------------------------------------------
# 4. Summary Statistics
# ---------------------------------------------------------------------------

summary_query = f"""
SELECT
  COUNT(*)                       AS total_rows,
  COUNT(DISTINCT plant_name)     AS distinct_plants,
  COUNT(DISTINCT pathogen)       AS distinct_pathogens,
  COUNT(DISTINCT plant_region)   AS distinct_regions,
  MIN(sample_collection_date)    AS earliest_date,
  MAX(sample_collection_date)    AS latest_date
FROM `{DATASET_REF}.all`
"""

print("\nSummary Statistics:")
print("-" * 40)
summary = client.query(summary_query).to_dataframe()
for col in summary.columns:
    print(f"  {col:25s} {summary[col].iloc[0]}")

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------

print("\nDone. All queries completed successfully.")
