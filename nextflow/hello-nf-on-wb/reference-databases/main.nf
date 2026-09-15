#!/usr/bin/env nextflow

// A reference is a file input: Nextflow stages it into the task, even from GCS.
process summarizeReference {
    publishDir params.outdir, mode: 'copy'

    input:
    path reference, name: 'reference.fasta', arity: '1'
    path annotations, name: 'annotations.csv', arity: '1'
    path summary_script, name: 'reference_utils.py', arity: '1'
    val expected_sha256
    val annotations_sha256

    output:
    path 'reference-summary.json'

    script:
    """
    python3 reference_utils.py reference.fasta '${expected_sha256}' annotations.csv '${annotations_sha256}' > reference-summary.json
    """
}

workflow {
    if (!(params.reference_sha256 ==~ /[a-fA-F0-9]{64}/) || !(params.annotations_sha256 ==~ /[a-fA-F0-9]{64}/)) {
        error 'Set reference_sha256 and annotations_sha256 to the SHA-256 values recorded in provenance.json.'
    }
    if (workflow.profile.tokenize(',').contains('workbench') &&
        (!"${params.reference}".startsWith('gs://') || !"${params.annotations}".startsWith('gs://') || !"${params.outdir}".startsWith('gs://'))) {
        error 'On Workbench, reference, annotations, and outdir must be gs:// paths. Use the generated params.workbench.json.'
    }
    summarizeReference(
        file(params.reference, checkIfExists: true),
        file(params.annotations, checkIfExists: true),
        file("${projectDir}/reference_utils.py", checkIfExists: true),
        params.reference_sha256,
        params.annotations_sha256
    )
    summarizeReference.out.view { "Reference summary: ${it}" }
}
