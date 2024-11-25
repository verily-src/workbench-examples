
# JUMP-Cell Painting Consortium CellProfiler WDL workflows

## Introduction

The [JUMP-Cell Painting Consortium](https://jump-cellpainting.broadinstitute.org/) created a new
data-driven approach to drug discovery based on cellular imaging, image analysis, and high
dimensional data analytics. See this preprint: [JUMP Cell Painting dataset: morphological impact of
136,000 chemical and genetic
perturbations](https://www.biorxiv.org/content/10.1101/2023.03.23.534023v2) for more detail. You can
find information on the resulting [datasets here](https://github.com/jump-cellpainting/datasets).

One goal of this effort was to provide workflows for Cell Profiling tasks. This workspace ports the
CellProfiler WDL workflows [here](https://app.terra.bio/#workspaces/cell-imaging/cellpainting) to
Verily Workbench, along with some sample data. That original workspace has more background on the
project and images. The workflow code is unchanged, with one exception: the
`cellprofiler_distributed_utils.wdl` file, imported by some of the `.wdl` files, was moved to the
same GCS directory as the other WDLs.

To get started, first **Duplicate** this workspace by clicking on the 'three-dot' menu at the top
right of the workspace window. This process will copy the `wdls` *controlled resource* bucket to
your new workspace, and will create a *referenced resource* for the `images` bucket.  This will let
you access the plate images read-only without needing to copy all of them into your workspace.
Finally, a fresh `wdl_runs` controlled bucket will be created for you.

Then, visit your new cloned workspace to continue.

## Running the workflows

### Note the URI of your `wdl_runs` bucket for outputs and run logs

We'll use the `wdl_runs` controlled bucket for holding run logs and outputs.  Click on the
`wdl_runs` bucket under the "Resources" tab and note its `gs://...` URI in the right-hand panel.
You'll use this for specifying workflow output paths.

In the following, for any parameter that includes `gs://<WDL_RUNS_BUCKET>`, replace it with this
`gs://...` URI instead. The examples below suggests that you incorporate a timestamp into the output
file paths— indicated as `<timestamp>`, so that you can distinguish between multiple run results,
but the path can be whatever you like, as long as you note what you used.

### Running a workflow

Navigate to the "Workflows" panel, and click to select a workflow.

This will bring up a right-hand panel with information about the WDL file.  Select "New job". Give
the job a name (or take the default), then in the next window of the dialog you'll enter the job
inputs— specified in more detail below for each workflow. If you don't see all the indicated
parameters, **uncheck** the box for "Show require inputs only", so that all inputs are displayed.

For the "Output bucket" in the next "Set up outputs" window of the dialog, chose `wdl_runs`.

Once a workflow job is launched, you can see its information in the "Job status" view of the
"Workflows" panel in your workspace.

See [Use the Cromwell engine to run WDL
workflows](https://support.workbench.verily.com/docs/guides/workflows/cromwell/) for more detail.

### Run the workflows in the order specified below

The workflows should be **run in the order specified below**, as results from one workflow are used
as inputs for the next.

Note that the Verily Workbench Workflows UI does not yet display the input parameters as part of the
job logs, so for each workflow you will **need to make note of the output file path(s) that you
specify**, in order to specify those files as inputs for following workflows. The following sections
provide more detail.


### 1. create_load_data workflow

Example inputs for the **create_load_data** wdl.  For the output path, use the URI of your `wdl_runs`
bucket instead of `gs://<WDL_RUNS_BUCKET>`, and fill in the `<timestamp>`, as described above.

- **plate_id**: `BR00116991`

- **config_yaml:** `gs://cloned-wdls-wb-jaunty-lettuce-7538/config/chandrasekaran_config.yml`

- **destination_directory_gsurl**: `gs://<WDL_RUNS_BUCKET>/results/<timestamp>/BR00116991`

- **images_directory_gsutl**: `gs://images-wb-jaunty-lettuce-7538/source_4_images/images/2020_11_04_CPJUMP1/images/BR00116991__2020-11-05T19_51_35-Measurement1/Images/Images`

### 2. cp_illumination_pipeline workflow

Example inputs for the **cp_illumination_pipeline** wdl.  Again, for the output path, use the URI of
your `wdl_runs` bucket instead of `gs://<WDL_RUNS_BUCKET>`, and fill in the `<timestamp>`, as
described above.

inputs for **cp_illumination_pipeline params**:

- **cppipe_file**: `gs://cloned-wdls-wb-jaunty-lettuce-7538/cellprofiler_pipelines/illum_without_batchfile.cppipe`

- **images_directory_gsurl** :
`gs://images-wb-jaunty-lettuce-7538/source_4_images/images/2020_11_04_CPJUMP1/images/BR00116991__2020-11-05T19_51_35-Measurement1/Images/Images`

- **load_data** (this file was generated in the **create_load_data** run):
`gs://<WDL_RUNS_BUCKET>/results/<timestamp>/BR00116991/load_data.csv`

- **output_illum_directory_gsurl** :
`gs://<WDL_RUNS_BUCKET>/results/<timestamp>/illum_pipeline`

### 3. cpd_analysis_pipeline workflow

Example inputs for the **cpd_analysis_pipeline** wdl.  As above, first replace with your bucket
name and file path as indicated.

- **cppipe_file**:
`gs://cloned-wdls-wb-jaunty-lettuce-7538/cellprofiler_pipelines/CPJUMP1_analysis_without_batchfile_406.cppipe`

- **images_directory_gsurl**:
`gs://images-wb-jaunty-lettuce-7538/source_4_images/images/2020_11_04_CPJUMP1/images/BR00116991__2020-11-05T19_51_35-Measurement1/Images/Images`

- **load_data_with_illum_csv** (this file was generated in the **create_load_data** run):
`gs://<WDL_RUNS_BUCKET>/results/<timestamp>/BR00116991/load_data_with_illum.csv`

- **output_directory_gsurl**:
`gs://<WDL_RUNS_BUCKET>/results/<timestamp>/analysis_pipeline`

- **illum_directory_gsurl** (this was generated in the **cp_illumination_pipeline params** run):
`gs://<WDL_RUNS_BUCKET>/results/<timestamp>/illum_pipeline`

### 4. cytomining workflow

Example inputs for the **cytomining** wdl. As above, first replace with your bucket name and file path as indicated.

- **cellprofiler_analysis_directory_gsurl**:
`gs://<WDL_RUNS_BUCKET>/results/<timestamp>/analysis_pipeline` (this was generated in the **cpd_analysis_pipeline workflow** run)

- **output_directory_gsurl**:
`gs://<WDL_RUNS_BUCKET>/results/<timestamp>/cytomining`

- **plate_id**: BR00116991

- **plate_map_file**:
`gs://cloned-wdls-wb-jaunty-lettuce-7538/plate_maps/JUMP-Target-1_compound_platemap.tsv`
