# ============================================================================
# Accessing BigQuery Datasets in Workbench
# ============================================================================
#
# Demonstrates how to query a BigQuery dataset from a Verily Workbench cloud
# environment using the bigrquery R package.
#
# Dataset: wb-crisp-bean-1269.world_soccer_games_wastewater_data
#
# The dataset contains national wastewater pathogen surveillance data,
# including measurements from over 2,000 treatment plants across the
# United States.
#
# Usage:
#   Rscript bq_access.R
# ============================================================================

library(bigrquery)

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

data_project    <- "wb-crisp-bean-1269"
dataset         <- "world_soccer_games_wastewater_data"

billing_project <- Sys.getenv("GOOGLE_CLOUD_PROJECT", unset = "")
if (billing_project == "") billing_project <- Sys.getenv("GOOGLE_PROJECT", unset = "")
if (billing_project == "") billing_project <- trimws(system("gcloud config get-value project 2>/dev/null", intern = TRUE))
if (billing_project == "") billing_project <- data_project

# ---------------------------------------------------------------------------
# 1. List Tables in the Dataset
# ---------------------------------------------------------------------------

cat("== 1. List Tables ==\n\n")

tables <- bq_dataset_tables(bq_dataset(data_project, dataset))
cat("Found", length(tables), "table(s) in", paste0(data_project, ".", dataset), ":\n\n")
for (t in tables) {
  cat("  -", t$table, "\n")
}

# ---------------------------------------------------------------------------
# 2. Inspect Table Schema
# ---------------------------------------------------------------------------

cat("\n== 2. Table Schema ==\n\n")

table_ref <- bq_table(data_project, dataset, "all")
meta      <- bq_table_meta(table_ref)

cat("Table: ", paste(data_project, dataset, "all", sep = "."), "\n")
cat("Rows:  ", format(as.numeric(meta$numRows), big.mark = ","), "\n")
cat("Size:  ", round(as.numeric(meta$numBytes) / 1e6, 1), "MB\n")

fields <- meta$schema$fields
cat("\nSchema (", length(fields), " columns):\n", sep = "")
for (f in fields) {
  cat(sprintf("  %-30s %-10s  %s\n", f$name, f$type,
              ifelse(is.null(f$description), "", f$description)))
}

# ---------------------------------------------------------------------------
# 3. Preview Data
# ---------------------------------------------------------------------------

cat("\n== 3. Preview Data ==\n\n")

preview_sql <- sprintf("SELECT * FROM `%s.%s.all` LIMIT 10", data_project, dataset)
cat("Running:", preview_sql, "\n\n")
df <- bq_table_download(bq_project_query(billing_project, preview_sql))
print(as.data.frame(df))

# ---------------------------------------------------------------------------
# 4. Summary Statistics
# ---------------------------------------------------------------------------

cat("\n== 4. Summary Statistics ==\n\n")

summary_sql <- sprintf("
SELECT
  COUNT(*)                       AS total_rows,
  COUNT(DISTINCT plant_name)     AS distinct_plants,
  COUNT(DISTINCT pathogen)       AS distinct_pathogens,
  COUNT(DISTINCT plant_region)   AS distinct_regions,
  MIN(sample_collection_date)    AS earliest_date,
  MAX(sample_collection_date)    AS latest_date
FROM `%s.%s.all`
", data_project, dataset)

summary_df <- bq_table_download(bq_project_query(billing_project, summary_sql))
print(as.data.frame(summary_df))

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------

cat("\nDone. All queries completed successfully.\n")
