# Project Baseline: cohort feasibility with Workbench AI

The same analysis as `cohort_feasibility_python.ipynb` and `cohort_feasibility_r.ipynb`, done by asking
questions in plain English. The AI assistant writes and runs the SQL inside the workspace, so it can
only reach data the signed-in user is allowed to see.

## Setup (about 5 minutes, once per app)

1. In a workspace with the Project Baseline Health Study (Limited Tier) data collection, create a
   **Workbench AI** app and open a terminal.
2. Clone this repo (or add it to the workspace as a Git repository resource) and install the Baseline skill,
   which tells the assistant where the tables are and how the data is coded:
   ```bash
   mkdir -p ~/.claude/skills
   cp -r ~/repos/workbench-examples/claude/skills/project-baseline ~/.claude/skills/
   ```
3. Start the assistant with `claude`.

## Prompts

Ask these in order in one session. Each builds on the one before. Expected answers come from the
notebooks; the assistant's wording will vary, but the numbers should match.

### 1. Orient

> What Project Baseline data do we have in this workspace?

**Expect:** the BigQuery datasets (`screener`, `crf`, `analysis`, `externallab`, `corelabreads`,
`appsurveys`, `admin`) and 2,502 participants with an enrollment visit and 4 annual visits.

### 2. Start the cohort

> How many participants have asthma in their medical history? How many of those were 18 to 40 at enrollment?

**Expect:** 398 with asthma, then 163 aged 18-40.

### 3. Finish the funnel

> Of those 163, how many take an asthma or airway medication (ATC class R03), don't have COPD, and
> attended at least 3 annual visits? Show me the count after each step.

**Expect:**

| Step | Participants |
|---|---|
| All participants | 2,502 |
| Asthma | 398 |
| Age 18-40 | 163 |
| R03 airway medication | 66 |
| No COPD | 66 |
| 3+ annual visits | 51 |

### 4. Characterize

> Compare those 51 with everyone else: age, sex, race, BMI, average PHQ-9 over the first study year, and
> hs-CRP at enrollment. Give me a Table 1 with medians and IQRs.

**Expect:**

| | Eligible (51) | Not eligible (2,451) |
|---|---|---|
| Age, median [IQR] | 30.0 [26.5-36.0] | 50.0 [35.0-64.0] |
| Female, % | 55 | 55 |
| Non-White, % | 49 | 37 |
| BMI, median [IQR] | 26.2 [23.5-30.1] | 26.9 [23.6-31.8] |
| PHQ-9, median [IQR] | 4.8 [2.0-8.0] | 3.0 [1.0-6.0] |
| hs-CRP mg/L, median [IQR] | 1.4 [0.7-5.1] | 1.2 [0.6-3.0] |

The assistant may break race into categories rather than White/non-White; the White share should be 51% vs. 63%.
If PHQ-9 comes out as 4 rather than 4.8, it used each person's first score instead of the first-year
average. Ask "which PHQ-9 values did you use?" That's a good moment to show that the assistant explains
its choices.

### 5. Ask a follow-up a notebook would need new code for

> Which airway medications are most common in those 51 people?

**Expect:** salbutamol (albuterol) first, by a wide margin (about 36 participants), then mometasone and
fluticasone (about 11 each).

### 6. Save it

> Save the cohort as a CSV, along with the SQL that defines it, to the shared-work bucket.

**Expect:** the files appear in the workspace bucket (check in the Resources tab). Change `shared-work` to
whichever bucket resource your workspace has.

## If an answer looks wrong

| Symptom | Likely cause | Say |
|---|---|---|
| R03 step is much lower than 66 (e.g. about 15) | Matched `Level2_Code = 'R03'`, which drops multi-class drugs | "ATC codes are multi-valued; match R03 with REGEXP_CONTAINS." |
| Asthma count above 398 | Counted rows, not people | "Count distinct USUBJID." |
| It can't find the tables | Skill not installed, or resources named differently | "Use `wb resolve --name crf` to find the tables." |

## Talking points

- The researcher never wrote SQL, but every query is visible and can be copied into a notebook.
- The assistant runs inside the governed workspace with the user's own permissions. It can't see data
  the user can't, and nothing leaves the workspace.
- The skill file is plain text in a Git repo. Teams can version and share domain knowledge the same way
  they share code.

*The eligibility criteria are hypothetical and for illustration only.*
