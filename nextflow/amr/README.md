[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Nextflow](https://img.shields.io/badge/Nextflow-%E2%89%A50.25.1-brightgreen.svg)](https://www.nextflow.io/)

# AMR++ Bioinformatic Pipeline

AMR++ is a bioinformatic pipeline for analyzing raw sequencing reads to characterize the profile of antimicrobial resistance genes, or resistome. Developed to work with the [MEGARes database](https://megares.meglab.org/), it contains sequence data for approximately 9,000 hand-curated antimicrobial resistance genes with an annotation structure optimized for high-throughput sequencing and metagenomic analysis.

This repository is adapted from the [original AMR++ pipeline](https://github.com/Microbial-Ecology-Group/AMRplusplus) with simplified scripts for running in local, GCP, and Verily Workbench environments.

## Summary of Changes

This adaptation includes the following modifications:
- **Multi-environment support**: Added scripts and configurations for local (Docker), GCP (Google Batch), and Verily Workbench execution
- **Containerization improvements**: Updated Dockerfile to bundle AMR++ bin scripts directly in the container at `/opt/amrplusplus/bin/`
- **Nextflow version**: Pinned to Nextflow 24 for consistency across environments
- **Module updates**: Modified alignment, microbiome (Kraken2), and resistome modules to use containerized paths instead of `$baseDir/bin/`
- **Environment templates**: Added configuration templates for local, GCP, and Workbench deployments (`scripts/config/*.env.template`)
- **Utility scripts**: Added `build.sh`, `run.sh`, `setup_infra.sh`, and `upload_data.sh` for simplified workflow management

## Quick Start

This repository provides simplified scripts for running AMR++ in three different environments:

1. **Local** - Run on your machine using Docker
2. **GCP** - Run on Google Batch with local Nextflow orchestration
3. **Workbench** - Run on Google Batch with Verily Workbench

### Prerequisites

- **For local execution**: Docker, Conda (with AMR++_env), Nextflow
- **For GCP execution**: Google Cloud SDK (`gcloud`), Docker
- **For Workbench execution**: Verily Workbench CLI (`wb`), Google Cloud SDK

## Environment Setup

### 1. Create Configuration Files

Copy the template files and customize them with your values:

```bash
# For local environment
cp scripts/config/local.env.template scripts/config/local.env

# For GCP environment
cp scripts/config/gcp.env.template scripts/config/gcp.env

# For Workbench environment
cp scripts/config/wb.env.template scripts/config/wb.env
```

### 2. Edit Configuration Files

Each `.env` file has two sections:
- **USER CONFIGURATION**: Values you must update (marked with `<PLACEHOLDER>`)
- **AUTOMATIC CONFIGURATION**: Auto-generated values (do not modify)

#### local.env
Update the following:
- `IMAGE_NAME`: Replace `<YOUR_DOCKERHUB_USERNAME>` with your Docker Hub username
  - Example: `"johndoe/amrplusplus-workbench"`

#### gcp.env
Update the following:
- `GCS_BUCKET`: Replace `<YOUR_BUCKET_NAME>` with your GCS bucket name (without `gs://` prefix)
  - Example: `my-nextflow-data`
- `GOOGLE_ARTIFACT_REPO`: Replace `<YOUR_ARTIFACT_REPO>` with your artifact registry repository name
  - Example: `nextflow-containers`
- `GCS_BUCKET_LOCATION`: Optionally change the region (default: `us-central1`)

#### wb.env
Update the following:
- `GCS_BUCKET`: Replace `<YOUR_BUCKET_ID>` with your Workbench GCS bucket resource ID
  - Example: `nf-output`
- `GOOGLE_ARTIFACT_REPO`: Replace `<YOUR_ARTIFACT_REPO>` with your artifact registry repository name
  - Example: `nextflow-containers`
- `GCS_BUCKET_LOCATION`: Optionally change the region (default: `us-central1`)

**Note:** Project IDs, service accounts, and registry paths are automatically determined from your `gcloud` and `wb` CLI configurations.

## Usage

### Building Docker Images

```bash
# Build for local use
./scripts/build.sh

# Build for GCP and push to registry
./scripts/build.sh --env gcp --push

# Build for Workbench and push to registry
./scripts/build.sh --env wb --push
```

### Running the Pipeline

```bash
# Run locally with Docker
./scripts/run.sh

# Run on Google Batch with local orchestration
./scripts/run.sh --env gcp

# Run on Google Batch with Workbench orchestration
./scripts/run.sh --env wb
```

### Infrastructure Setup (Cloud Environments)

For GCP or Workbench environments, set up the required infrastructure first:

```bash
# Set up infrastructure for GCP environment
./scripts/setup_infra.sh gcp

# Set up infrastructure for Workbench environment
./scripts/setup_infra.sh wb
```

### Data Upload (Cloud Environments)

Upload your data to GCS before running cloud pipelines:

```bash
# Upload data for GCP environment
./scripts/upload_data.sh gcp

# Upload data for Workbench environment
./scripts/upload_data.sh wb
```

## Environment Details

### Local Environment
- **Description**: Run Nextflow locally using Docker containers
- **Requirements**: Docker daemon, Conda environment (AMR++_env)
- **Profile**: `docker`
- **Use case**: Testing, development, small datasets

### GCP Environment
- **Description**: Run on Google Batch with local Nextflow orchestration
- **Requirements**: `gcloud` CLI configured, GCS bucket, Artifact Registry
- **Profile**: `google-batch`
- **Use case**: Large-scale processing with cloud resources, local monitoring

### Workbench Environment
- **Description**: Run on Google Batch with Verily Workbench orchestration
- **Requirements**: Workbench workspace, `wb` CLI, Workbench-managed resources
- **Profile**: `workbench`
- **Use case**: Collaborative analysis in Verily Workbench environment

## Pipeline Options

### Available Pipeline Workflows

AMR++ can be customized using the `--pipeline` parameter:

- **`demo`** (default): Simple demonstration on test data
- **`standard_AMR`**: QC trimming → Host DNA removal → Resistome alignment → Results
- **`fast_AMR`**: Same as standard but skips host removal for faster analysis
- **`standard_AMR_wKraken`**: Standard AMR + microbiome analysis with Kraken

### Pipeline Subworkflows

Run specific components independently:

- **`eval_qc`**: Evaluate sample QC
- **`trim_qc`**: QC trimming using Trimmomatic
- **`rm_host`**: Remove host DNA contamination
- **`resistome`**: Align to MEGARes, perform rarefaction and resistome analysis
- **`kraken`**: Taxonomic classification
- **`bam_resistome`**: Run resistome analysis starting from BAM files

### Optional Analysis Flags

#### SNP Verification
Include SNP-confirmed resistance gene counts:

```bash
nextflow run main_AMR++.nf --pipeline standard_AMR --snp Y
```

Output: `SNPconfirmed_AMR_analytic_matrix.csv` (in addition to standard count matrix)

#### Deduplicated Counts
Include deduplicated count analysis:

```bash
nextflow run main_AMR++.nf --pipeline standard_AMR --snp Y --deduped Y
```

**Note**: This significantly increases runtime and storage requirements.

### Example Commands

Run standard AMR++ workflow with all options:

```bash
# Local execution
nextflow run main_AMR++.nf -profile docker --pipeline standard_AMR --reads "data/raw/*_R{1,2}.fastq.gz" --snp Y --deduped Y

# GCP execution (after running ./scripts/setup_infra.sh gcp and ./scripts/upload_data.sh gcp)
./scripts/run.sh --env gcp

# Workbench execution (after running ./scripts/setup_infra.sh wb and ./scripts/upload_data.sh wb)
./scripts/run.sh --env wb
```

## AMR++ on Verily Workbench

### Quick Demo in Workbench JupyterLab

Create a new Workbench workspace and add this git repository in the **Apps** tab.

Create a JupyterLab app instance, launch it, and open the terminal:

```bash
# Initialize conda
conda init
source ~/.bashrc

# Navigate to the repository
cd repos/AMRplusplus

# Create and activate the conda environment
conda env create -f envs/AMR++_env.yaml
conda activate AMR++_env

# Verify Nextflow version 24 is installed
nextflow -v

# Run the test pipeline (takes ~5 minutes)
nextflow run main_AMR++.nf
```

Expected output: **Succeeded: 24** with results in `~/repos/AMRplusplus/test_results`

### Production Workbench Deployment

For production use with Google Batch:

1. **Setup infrastructure**:
   ```bash
   ./scripts/setup_infra.sh wb
   ```

2. **Upload your data**:
   ```bash
   ./scripts/upload_data.sh wb
   ```

3. **Run the pipeline**:
   ```bash
   ./scripts/run.sh --env wb
   ```

Results will be stored in your Workbench GCS bucket.

## Configuration Files

Environment-specific variables are stored in `scripts/config/*.env` files (created from `.env.template` files). These files contain:
- GCS bucket names and locations
- Docker image names and tags
- Service account configurations
- Nextflow profiles and configs

**Security Note**: The `.env` files are gitignored to prevent committing sensitive information. Only template files are tracked in version control.

## Additional Resources

**Original AMR++ Repository**: [https://github.com/Microbial-Ecology-Group/AMRplusplus](https://github.com/Microbial-Ecology-Group/AMRplusplus)

For more detailed information about the AMR++ pipeline:

- [Installation](https://github.com/Microbial-Ecology-Group/AMRplusplus/blob/master/docs/installation.md)
- [Usage](https://github.com/Microbial-Ecology-Group/AMRplusplus/blob/master/docs/usage.md)
- [Configuration](https://github.com/Microbial-Ecology-Group/AMRplusplus/blob/master/docs/configuration.md)
- [Output](https://github.com/Microbial-Ecology-Group/AMRplusplus/blob/master/docs/output.md)
- [Dependencies](https://github.com/Microbial-Ecology-Group/AMRplusplus/blob/master/docs/dependencies.md)
- [FAQs](https://github.com/Microbial-Ecology-Group/AMRplusplus/blob/master/docs/FAQs.md)

## License

MIT License
