"""
UCSF Precision Oncology Dashboard
Flask + Plotly.js — 4-tab dashboard querying BigQuery data collections.
"""

import json
from flask import Flask, render_template, jsonify
from flask_cors import CORS
from google.cloud import bigquery

app = Flask(__name__)
app.config["STRICT_SLASHES"] = False
CORS(app)

PATIENT_TABLE = "wb-potent-shallot-9879.hnscc_clinical_data.patients"
MUTATION_TABLE = "wb-twinkly-banana-2547.hnscc_genomics_data.somatic_mutations"
DRUG_TABLE = "wb-sunny-pecan-1742.hnscc_drug_target_data.drug_targets"
TRIAL_TABLE = "wb-sunny-pecan-1742.hnscc_drug_target_data.clinical_trials"

_cache = {}


def bq_query(query, cache_key=None):
    if cache_key and cache_key in _cache:
        return _cache[cache_key]
    client = bigquery.Client()
    df = client.query(query).to_dataframe()
    result = df.to_dict(orient="records")
    if cache_key:
        _cache[cache_key] = result
    return result


@app.route("/")
def index():
    return render_template("index.html")


@app.route("/api/cohort-overview")
def cohort_overview():
    patients = bq_query(f"SELECT * FROM `{PATIENT_TABLE}`", "patients")
    import pandas as pd
    df = pd.DataFrame(patients)

    age_bins = [30, 40, 50, 60, 70, 80, 90]
    age_labels = ["30-39", "40-49", "50-59", "60-69", "70-79", "80-89"]
    df["age_group"] = pd.cut(df["age"], bins=age_bins, labels=age_labels, right=False)

    return jsonify({
        "total_patients": len(df),
        "median_age": float(df["age"].median()),
        "sex_distribution": df["sex"].value_counts().to_dict(),
        "race_distribution": df["race"].value_counts().to_dict(),
        "stage_distribution": df["stage"].value_counts().reindex(["I", "II", "III", "IV"], fill_value=0).to_dict(),
        "hpv_status": df["hpv_status"].value_counts().to_dict(),
        "smoking_status": df["smoking_status"].value_counts().to_dict(),
        "primary_site": df["primary_site"].value_counts().to_dict(),
        "age_distribution": df["age_group"].value_counts().sort_index().to_dict(),
        "treatment_counts": {
            "Platinum chemotherapy": int(df["treatment"].str.contains("Platinum").sum()),
            "Pembrolizumab": int(df["treatment"].str.contains("Pembrolizumab").sum()),
            "Radiation": int(df["treatment"].str.contains("Radiation").sum()),
            "Surgery": int(df["treatment"].str.contains("Surgery").sum()),
        },
        "response_distribution": df["response"].value_counts().reindex(["CR", "PR", "SD", "PD"], fill_value=0).to_dict(),
    })


@app.route("/api/mutation-landscape")
def mutation_landscape():
    mutations = bq_query(f"SELECT * FROM `{MUTATION_TABLE}`", "mutations")
    patients = bq_query(f"SELECT patient_id FROM `{PATIENT_TABLE}`", "patient_ids")
    import pandas as pd
    df = pd.DataFrame(mutations)
    n_patients = len(set(p["patient_id"] for p in patients))

    gene_freq = (
        df.groupby("gene")["patient_id"]
        .nunique()
        .sort_values(ascending=False)
        .to_dict()
    )
    gene_pct = {g: round(c / n_patients * 100, 1) for g, c in gene_freq.items()}

    top_genes = list(gene_freq.keys())[:10]
    df_top = df[df["gene"].isin(top_genes)]
    patient_genes = df_top.groupby("patient_id")["gene"].apply(set).to_dict()

    cooccurrence = {}
    for g1 in top_genes:
        cooccurrence[g1] = {}
        for g2 in top_genes:
            count = sum(1 for genes in patient_genes.values() if g1 in genes and g2 in genes)
            cooccurrence[g1][g2] = count

    impact_dist = df["functional_impact"].value_counts().to_dict()
    significance_dist = df["clinical_significance"].value_counts().to_dict()

    return jsonify({
        "gene_frequency": gene_freq,
        "gene_percentage": gene_pct,
        "cooccurrence": cooccurrence,
        "top_genes": top_genes,
        "functional_impact": impact_dist,
        "clinical_significance": significance_dist,
        "total_mutations": len(df),
    })


@app.route("/api/drug-target-map")
def drug_target_map():
    mutations = bq_query(f"SELECT * FROM `{MUTATION_TABLE}`", "mutations")
    drugs = bq_query(f"SELECT * FROM `{DRUG_TABLE}`", "drugs")
    trials = bq_query(f"SELECT * FROM `{TRIAL_TABLE}`", "trials")
    import pandas as pd

    mut_df = pd.DataFrame(mutations)
    drug_df = pd.DataFrame(drugs)
    trial_df = pd.DataFrame(trials)

    mutated_genes = mut_df["gene"].unique().tolist()

    actionable = drug_df[drug_df["target_gene"].isin(mutated_genes)].to_dict(orient="records")

    relevant_trials = []
    for _, trial in trial_df.iterrows():
        drug_name = trial["drug"]
        matching_drugs = drug_df[drug_df["drug_name"].str.contains(drug_name.split(" ")[0], case=False, na=False)]
        if not matching_drugs.empty:
            target = matching_drugs.iloc[0]["target_gene"]
            if target in mutated_genes:
                relevant_trials.append(trial.to_dict())
        if "HNSCC" in str(trial.get("cancer_type", "")):
            if trial.to_dict() not in relevant_trials:
                relevant_trials.append(trial.to_dict())

    gene_patients = mut_df.groupby("gene")["patient_id"].nunique().to_dict()
    gene_drug_map = []
    for gene in mutated_genes:
        gene_drugs = drug_df[drug_df["target_gene"] == gene]
        for _, d in gene_drugs.iterrows():
            gene_drug_map.append({
                "gene": gene,
                "patients_affected": gene_patients.get(gene, 0),
                "drug_name": d["drug_name"],
                "mechanism": d["mechanism"],
                "fda_status": d["fda_status"],
                "indication": d["indication"],
            })

    return jsonify({
        "actionable_drugs": actionable,
        "relevant_trials": relevant_trials[:30],
        "gene_drug_map": gene_drug_map,
        "mutated_genes": mutated_genes,
    })


@app.route("/api/treatment-outcomes")
def treatment_outcomes():
    patients = bq_query(f"SELECT * FROM `{PATIENT_TABLE}`", "patients")
    mutations = bq_query(f"SELECT * FROM `{MUTATION_TABLE}`", "mutations")
    import pandas as pd
    pat_df = pd.DataFrame(patients)
    mut_df = pd.DataFrame(mutations)

    response_by_hpv = pat_df.groupby(["hpv_status", "response"]).size().reset_index(name="count")
    hpv_response = {}
    for _, row in response_by_hpv.iterrows():
        key = row["hpv_status"]
        if key not in hpv_response:
            hpv_response[key] = {}
        hpv_response[key][row["response"]] = int(row["count"])

    hpv_survival = pat_df.groupby("hpv_status").agg(
        median_pfs=("pfs_months", "median"),
        median_os=("os_months", "median"),
        mean_pfs=("pfs_months", "mean"),
        mean_os=("os_months", "mean"),
    ).round(1).to_dict(orient="index")

    key_genes = ["TP53", "PIK3CA", "RET", "HRAS", "CDKN2A", "NOTCH1"]
    gene_outcomes = {}
    for gene in key_genes:
        gene_patients = set(mut_df[mut_df["gene"] == gene]["patient_id"])
        if not gene_patients:
            continue
        gene_pat_df = pat_df[pat_df["patient_id"].isin(gene_patients)]
        non_gene_pat_df = pat_df[~pat_df["patient_id"].isin(gene_patients)]
        gene_outcomes[gene] = {
            "n_patients": len(gene_pat_df),
            "response_dist": gene_pat_df["response"].value_counts().to_dict(),
            "median_os": round(float(gene_pat_df["os_months"].median()), 1),
            "median_pfs": round(float(gene_pat_df["pfs_months"].median()), 1),
            "non_mutated_median_os": round(float(non_gene_pat_df["os_months"].median()), 1),
            "non_mutated_median_pfs": round(float(non_gene_pat_df["pfs_months"].median()), 1),
        }

    stage_outcomes = pat_df.groupby("stage").agg(
        median_os=("os_months", "median"),
        median_pfs=("pfs_months", "median"),
        n=("patient_id", "count"),
    ).round(1).to_dict(orient="index")

    return jsonify({
        "hpv_response": hpv_response,
        "hpv_survival": hpv_survival,
        "gene_outcomes": gene_outcomes,
        "stage_outcomes": stage_outcomes,
        "overall_response": pat_df["response"].value_counts().to_dict(),
    })


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080, debug=False, threaded=True)
