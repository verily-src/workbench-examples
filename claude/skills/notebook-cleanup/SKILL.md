---
  name: notebook-cleanup
  description: Clears all JupyterLab notebook cell outputs and generates HTML snapshots for review. HTML snapshots are committed to the repo in a directory mirroring the notebook's location.

  ---

  # Notebook Cleanup Skill

  Clean up JupyterLab notebooks for commit by clearing all cell outputs and generating HTML snapshots for reviewer convenience.

  ## Behavior

  When invoked, this skill will:

  1. **Discover notebooks** — Find all `.ipynb` files that have been modified (staged or unstaged) in the current Git repository. If no modified notebooks are found, scan the entire repo and prompt the user to select which notebooks to clean.
  
  2. **Generate HTML snapshots** — For each notebook, export an HTML snapshot before clearing outputs. Store the HTML file in a `notebook-snapshots` directory that mirrors the notebook's relative path in the repo. For example:
     - `src/analysis/exploration.ipynb` → `.notebook-snapshots/src/analysis/exploration.html`

  3. **Clear cell outputs** — Strip all cell outputs and execution counts from each `.ipynb` file in place, preserving the notebook structure and source code.

  4. **Stage snapshot files** — Add the generated HTML snapshots to the Git staging area alongside the cleaned notebooks so they are included in the commit.

  5. **Report results** — Summarize what was cleaned and where HTML snapshots were saved.

  ## Usage
  
  Invoke this skill when:
  - Preparing notebooks for a pull request
  - The user asks to clean or prepare notebooks for commit

  ## Requirements

  - The working directory must be within a Git repository

  ## Example

  User calls: /notebook-cleanup

  **Output:**
  Cleaned 3 notebooks:
  - src/analysis/exploration.ipynb (outputs cleared)
  - src/analysis/validation.ipynb (outputs cleared)
  - src/models/training_run.ipynb (outputs cleared)
  
  HTML snapshots saved to notebook-snapshots/:
  - notebook-snapshots/src/analysis/exploration.html
  - notebook-snapshots/src/analysis/validation.html
  - notebook-snapshots/src/models/training_run.html
  
  All files staged for commit.