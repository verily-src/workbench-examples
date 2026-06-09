# Stata 19 on Verily Workbench

Install and configure [StataNow 19](https://www.stata.com/) in a Workbench JupyterLab app.

## Prerequisites

- Upload `StataNow19Linux64.tar.gz` to `~/workspace/uploads/stata/`
- A valid Stata license (serial number, code, and authorization)

## Installation

### Step 1: Install Stata

```bash
sudo bash ~/repos/workbench-examples/stata/install_stata.sh
```

The installer prompts interactively — answer `y` to confirm each step. It extracts to a local temp directory (since the GCS-backed mount does not support `chmod`), then copies the installed files to `~/workspace/uploads/stata/stata19/`.

The copy step takes ~10-15 minutes due to the large number of files (~13,000).

### Step 2: Initialize the license

```bash
sudo bash ~/repos/workbench-examples/stata/run_stinit.sh
```

You will be prompted for your serial number, code, and authorization. The script copies Stata to a local temp directory to run `stinit`, then saves `stata.lic` back to the persistent mount.

This step can be run by a different user who holds the license credentials.

## Usage in Python

```python
import stata_setup
stata_setup.config("/home/jupyter/workspace/uploads/stata/stata19", "mp")
```

Replace `"mp"` with your licensed edition (`"mp"`, `"se"`, or `"be"`).

## File layout

```
~/workspace/uploads/stata/
  StataNow19Linux64.tar.gz   # Stata installer archive
  stata19/                    # Installed Stata (persistent)

~/repos/workbench-examples/stata/
  install_stata.sh            # Installation script
  run_stinit.sh               # License initialization script
  README.md                   # This file
```

## Notes

- The installation persists across app restarts because `~/workspace/` is backed by GCS.
- Scripts install to `/tmp` first and copy results to GCS because the GCS-fused mount does not support `chmod`/execute permissions.
- Reference: [Stata Linux install guide](https://www.stata.com/support/faqs/unix/install-download-on-linux/)
