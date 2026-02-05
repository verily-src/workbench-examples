[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Nextflow](https://img.shields.io/badge/Nextflow-v24-brightgreen.svg)](https://www.nextflow.io/)

# AMR++ Bioinformatic Pipeline

AMR++ is a bioinformatic pipeline for analyzing raw sequencing reads to characterize the profile of antimicrobial resistance genes, or resistome. Developed to work with the [MEGARes database](https://megares.meglab.org/), it contains sequence data for approximately 9,000 hand-curated antimicrobial resistance genes with an annotation structure optimized for high-throughput sequencing and metagenomic analysis.

**This repository demonstrates running AMR++ on Verily Workbench with orchestration through Workbench and compute on Google Batch.** It is adapted from the [original AMR++ pipeline](https://github.com/Microbial-Ecology-Group/AMRplusplus) with simplified scripts for cloud execution.

Additional environments are provided for testing and debugging:
- **Local** - For quick testing and development
- **GCP** - For debugging Google Batch jobs with visible logs (Workbench currently has permissions issues showing Batch logs)

## Dependencies

### Required for Workbench Deployment
- **Verily Workbench CLI** (`wb`) - Workbench command-line tool
- **Google Cloud SDK** (`gcloud`) - GCP command-line tool
- **Docker** - For building and pushing container images (must be running)
- **Nextflow v24** - Workflow orchestration (installed in Workbench app)
  - **Note**: v25 has breaking changes and is not compatible with this pipeline

**Important Notes**:
- Ensure Docker is running on your local machine before executing `./scripts/build.sh --env wb --push`
- You must be an **ADMIN** of the Workbench workspace where this pipeline will run

### Optional Dependencies (for testing/debugging environments)
- **Local**: Docker, Conda
- **GCP**: `gcloud`, Docker


## AMR++ on Verily Workbench

**Prerequisites**:
- You must create a Workbench workspace where you have **ADMIN** permissions
- All setup and execution must be done within this workspace

### Quick Start: Workbench Orchestration with Google Batch

This guide walks through setting up and running AMR++ with Workbench orchestration and Google Batch compute. The setup is split between local commands (for infrastructure) and Workbench app commands (for execution).

#### Step 1: Create Workspace and App

Create a new workspace and app in the Workbench UI (or use the CLI if preferred).

#### Step 2: Local Setup

Run these commands on your **local machine**:

```bash
# Set your active workspace (replace with your workspace ID)
wb workspace set --id=your-workspace-id

# Copy the Workbench environment template
cp scripts/config/wb.env.template scripts/config/wb.env
```

Edit `scripts/config/wb.env` and set the user-defined variables:
- `GCS_BUCKET`: Your Workbench GCS bucket resource ID (e.g., `nf-output`)
- `GOOGLE_ARTIFACT_REPO`: Your artifact registry repo (e.g., `nextflow-containers`)
- `GCS_BUCKET_LOCATION`: Region (default: `us-central1`)

**Notes**:
- Project IDs, service accounts, and registry paths are automatically determined from your `gcloud` and `wb` CLI configurations
- **Future Improvement**: Consider using separate buckets for input data and Nextflow output to better organize resources

Then run:

```bash
# Set up infrastructure (creates buckets, service accounts, etc.)
./scripts/setup_infra.sh wb

# Upload input data to GCS
./scripts/upload_data.sh wb

# Build Docker image and push to Artifact Registry
# NOTE: Docker must be running before executing this command
./scripts/build.sh --env wb --push
```

#### Step 3: Workbench App Setup

Open your Workbench app, launch the Terminal, and run:

```bash
# Clone the repository (adjust branch as needed)
cd repos/ && git clone -b samh/amr-dev https://github.com/verily-src/workbench-examples.git && cd workbench-examples/nextflow/amr-on-wb/

# Copy the environment template
cp scripts/config/wb.env.template scripts/config/wb.env
```

Now copy your local `wb.env` configuration into the Workbench app.

#### Step 4: Run the Pipeline

```bash
./scripts/run.sh --env wb
```

Results will be stored in your configured GCS bucket.

**Known Issues**:
- The `gcloud storage cp` command may not correctly resolve Workbench resource names to full `gs://` paths when running `upload_data.sh` or `run.sh`. If you encounter path resolution issues, manually specify the full GCS bucket path in your `wb.env` configuration.

---

### Alternative: Quick Demo in Workbench JupyterLab (Workbench Execution)

For a simple demonstration without Google Batch (both orchestration and execution running in the same Workbench app):

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

---

## Supporting Environments

The following environments are provided for testing and debugging purposes.

### Local Environment (Testing)

**Purpose**: Quick testing and development on small datasets

**Setup**:
```bash
cp scripts/config/local.env.template scripts/config/local.env
# Edit local.env and set IMAGE_NAME
./scripts/build.sh
./scripts/run.sh
```

**Requirements**: Docker, Conda

### GCP Environment (Debugging)

**Purpose**: Debug Google Batch jobs with visible logs (workaround for Workbench permissions issues)

**Setup**:
```bash
cp scripts/config/gcp.env.template scripts/config/gcp.env
# Edit gcp.env and set GCS_BUCKET, GOOGLE_ARTIFACT_REPO
./scripts/setup_infra.sh gcp
./scripts/upload_data.sh gcp
./scripts/build.sh --env gcp --push
./scripts/run.sh --env gcp
```

**Requirements**: `gcloud` CLI, Docker

**Configuration** (`gcp.env`):
- `GCS_BUCKET`: Your GCS bucket name (without `gs://` prefix)
  - Example: `my-nextflow-data`
- `GOOGLE_ARTIFACT_REPO`: Your artifact registry repository name
  - Example: `nextflow-containers`
- `GCS_BUCKET_LOCATION`: Region (default: `us-central1`)

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
