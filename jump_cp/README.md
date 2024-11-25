
## JUMP-Cell Painting workflows

The `dashboard.md` file in this directory— used for the workspace "Overview"— is paired with this workspace:
https://workbench.verily.com/workspaces/jump-cp-workflows-copy.  This workspace is intended to be shared read-only and *duplicated*, then the workflows run in the duplicated workspace.
Some of the information in the Overview is specific to the buckets of the source workspace and would need
to be modified to use with other source workspaces.

The cloning controlled resource buckets in https://workbench.verily.com/workspaces/jump-cp-workflows-copy
are set as follows:

- `images` bucket: `COPY_REFERENCE`  (This is a large read-only bucket. A reference to it will be created in a cloned workspace.)
- `wdl_runs`: `COPY_DEFINITION` (The bucket is created in the cloned workspace, but the contents are not copied.)
- `wdls`: `COPY_RESOURCE` (The bucket and its contents are created in the cloned workspace.)

