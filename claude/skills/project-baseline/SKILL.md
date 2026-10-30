---
name: project-baseline
description: Query the Project Baseline Health Study (Limited Tier) data collection in a Verily Workbench workspace. Use when the user asks about Baseline participants, cohorts, medical history, medications, labs, vitals, ECG/echo reads, or survey scores (PHQ-9, GAD-7, PROMIS, PSS).
---

# Project Baseline Health Study (Limited Tier)

Longitudinal, de-identified data on 2,502 adult participants (ages 18-92 at enrollment) with an
enrollment visit and 4 annual visits. The structure is CDISC-like, **not OMOP**.

## Finding the tables

The data collection adds BigQuery dataset resources to the workspace. Resolve each one before
querying; never guess project IDs:

```bash
wb resolve --name crf        # -> <project>.crf
```

| Resource | Key tables |
|---|---|
| `screener` | `DM` demographics: `age_at_enrollment` (STRING, cast to INT64), `SEX`, `RACE` |
| `crf` | `MH` medical history (`PTName` = MedDRA preferred term, e.g. 'Asthma'), `CM` medications, `VS` vitals, `VISDT1` visit attendance, `AE`, `GAD7`, `PHQ9`, `IMG*` |
| `analysis` | Derived tables: `DIAGNOSES` (per-visit history flags such as `mh_major_depression`, `der_hx_diab`), `*_SCORES` (e.g. `PHQ9A_SCORES.PHQ9_SUM_SCORE`) |
| `externallab` | `CLABS` lab results: test name `rtcname`, SI result `siurslt` (STRING, cast to FLOAT64), unit `siuunit`, reference range `siulow`/`siuhigh` |
| `corelabreads` | `ECG` (`QTCF`, `HR`, `QRS`, ...), `ECHO`, retinal and coronary calcium reads |
| `appsurveys` | Raw app survey items (PROMIS, PSS, PANAS, ...) |
| `admin` | Site and evaluation metadata |

Inspect a schema with `bq show --schema --format=prettyjson <project>:<dataset>.<table>`.

## Rules that avoid wrong answers

- **Participant key:** `USUBJID`, in every table. Count people with `COUNT(DISTINCT USUBJID)`.
- **Visits:** `VISIT` is a label (`STUDY_START`, `YEAR_ONE_ANNUAL_VISIT`, ... `YEAR_FOUR_ANNUAL_VISIT`).
  `VISITNUM` is 1 at enrollment, 2 at year 1, and so on. App surveys add quarterly suffixes
  (`STUDY_START_Q2`, VISITNUM 1.2). "Enrollment" or "baseline" means `VISIT = 'STUDY_START'`, or
  `VISITNUM < 2` for app surveys.
- **Medications are multi-coded.** `CM.ATC_Codes` and `CM.Level2_Code` hold every ATC class of a drug in
  one string (`G02CA:... || R03AC:...`). Match with `REGEXP_CONTAINS(ATC_Codes, 'R03')`, never `=`.
  An equality test silently drops multi-class drugs such as salbutamol.
- **ATC R03** (drugs for obstructive airway disease) includes relievers (salbutamol) as well as
  controllers (inhaled corticosteroids, montelukast). Don't call R03 users "on a controller".
- **Numbers stored as strings:** use `SAFE_CAST(... AS FLOAT64)` for `age_at_enrollment`, `siurslt`,
  `vs_height_cm`, `vs_weight_kg`, and ECG intervals.
- **BMI** = `vs_weight_kg / POW(vs_height_cm / 100, 2)` from `crf.VS` at `STUDY_START`.
- Medical-history rows repeat at each visit. Use `SELECT DISTINCT USUBJID` for "ever had".
- All participants are adults. If asked about children, say so; don't filter to an empty cohort.

## Working style

- Show the SQL you ran, then a short answer with the counts.
- For a cohort with several criteria, report a funnel: the count after each criterion, in order.
- Save outputs (CSV and the SQL) to a workspace bucket (`wb resolve --name <bucket>`), not only local disk.
- Report aggregates. Don't print lists of participant IDs unless asked.
