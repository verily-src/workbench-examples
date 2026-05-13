---
  name: notebook-cleanup
  description: Clears all JupyterLab notebook cell outputs, lints code and structure, and generates HTML snapshots for review. HTML snapshots are committed to the repo in a directory mirroring the notebook's location.

  ---

  # Notebook Cleanup Skill

  Clean up and lint JupyterLab notebooks for commit by clearing all cell outputs, validating code quality and notebook structure, and generating HTML snapshots for reviewer convenience.

  ## Behavior

  When invoked, this skill will:

  1. **Discover notebooks** — Find all `.ipynb` files that have been modified (staged or unstaged) in the current Git repository. If no modified notebooks are found, scan the entire repo and prompt the user to select which notebooks to clean.

  2. **Detect notebook language** — Read the notebook's kernel metadata to determine the language (Python, R, etc.) and apply language-appropriate linting rules.

  3. **Lint code cells** — Analyze all code cells for quality issues appropriate to the detected language:
     - Unused imports or library loads
     - Undefined or shadowed variables
     - Style violations (naming conventions, line length, whitespace)
     - Invalid syntax
     - Hardcoded credentials
     - No empty cells
     Report findings with cell numbers and suggested fixes

  4. **Validate standards compliance** — Check adherence to PR standards:
     - No cell outputs present in the committed `.ipynb` file
     - No data files staged for commit unless publicly available
     - Jira ticket referenced in the notebook or PR description
  
  5. **Generate HTML snapshots** — For each notebook, export an HTML snapshot before clearing outputs. Store the HTML file in a `notebook-snapshots` directory that mirrors the notebook's relative path in the repo. For example:
     - `src/analysis/exploration.ipynb` → `.notebook-snapshots/src/analysis/exploration.html`

 6. **Ensure provenance and copyright boilerplate** — Check that the notebook ends with the required boilerplate cells. If missing, append them. For Python notebooks,
   the provenance section includes:

     **Markdown cell:**
  Provenance
  
     Generate information about this notebook environment and the packages installed.

  **Code cell:** `!date`

  **Markdown cell:** `Conda and pip installed packages:`

  **Code cell:** `!conda env export`

  **Markdown cell:** `JupyterLab extensions:`
  
  **Code cell:** `!jupyter labextension list`

  **Markdown cell:** `Number of cores:`

  **Code cell:** `!grep ^processor /proc/cpuinfo | wc -l`

  **Markdown cell:** `Memory:`
  
  **Code cell:** `!grep "^MemTotal:" /proc/meminfo`

  **Markdown cell (copyright):**
  ---   Copyright  Verily Life Sciences LLC
  
     Use of this source code is governed by a BSD-style
     license that can be found in the LICENSE file or at
     https://developers.google.com/open-source/licenses/bsd

  For non-Python notebooks, only the copyright cell is appended (provenance cells are skipped).

 6. **Ensure provenance and copyright boilerplate** — Check that the notebook ends with the required boilerplate cells. If missing, append them. For Python notebooks, the provenance section includes:

    **Markdown cell:**
      Provenance
  
      Generate information about this notebook environment and the packages installed.

    **Code cell:** `!date`

    **Markdown cell:** `Conda and pip installed packages:`

    **Code cell:** `!conda env export`

    **Markdown cell:** `JupyterLab extensions:`
    
    **Code cell:** `!jupyter labextension list`

    **Markdown cell:** `Number of cores:`

    **Code cell:** `!grep ^processor /proc/cpuinfo | wc -l`

    **Markdown cell:** `Memory:`
    
    **Code cell:** `!grep "^MemTotal:" /proc/meminfo`

    **Markdown cell (copyright):**
    ---   Copyright  Verily Life Sciences LLC
    
      Use of this source code is governed by a BSD-style
      license that can be found in the LICENSE file or at
      https://developers.google.com/open-source/licenses/bsd

    For non-Python notebooks, only the copyright cell is appended (provenance cells are skipped).

  7. **Generate HTML snapshots** — For each notebook, export an HTML snapshot **before** clearing outputs. Store the HTML file in a `notebook-snapshots/` directory that mirrors the notebook's relative path in the repo. For example:
      `src/analysis/exploration.ipynb` → `notebook-snapshots/src/analysis/exploration.html`

  8. **Clear cell outputs** — Strip all cell outputs and execution counts from each `.ipynb` file in place, preserving the notebook structure and source code.

  9. **Stage snapshot files** — Add the generated HTML snapshots to the Git staging area alongside the cleaned notebooks so they are included in the commit.

  10. **Report results** — Summarize linting findings, what was cleaned, and where HTML snapshots were saved.

  ## Usage
  
  Invoke this skill when:
  - Preparing notebooks for a pull request
  - The user asks to clean, lint, or prepare notebooks for commit

  ## Requirements

  - The working directory must be within a Git repository

  ## Example

  User calls: /notebook-cleanup

  **Output:**
  Linting 3 notebooks...

  src/analysis/exploration.ipynb:
    ⚠ Cell 3: unused import 'pandas as pd' (never referenced)
    ✓ Structure: title present, markdown sections found

  src/analysis/validation.ipynb:
    ✓ Code: no issues found
    ✓ Structure: title present, markdown sections found

  src/models/training_run.ipynb:
    ✓ Code: no issues found
    ⚠ Structure: no markdown heading in first cell
    ⚠ Structure: empty cell at position 5

  Standards compliance:
    ✓ No data files staged
    ⚠ No Jira ticket reference found — ensure it is included in the PR description

  Cleaned 3 notebooks (outputs cleared):
  - src/analysis/exploration.ipynb
  - src/analysis/validation.ipynb
  - src/models/training_run.ipynb
  
  HTML snapshots saved to notebook-snapshots/:
  - notebook-snapshots/src/analysis/exploration.html
  - notebook-snapshots/src/analysis/validation.html
  - notebook-snapshots/src/models/training_run.html
  
  All files staged for commit.