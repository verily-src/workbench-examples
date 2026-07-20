#!/usr/bin/env nextflow

// Gather every uppercased greeting into one published result file. On the
// workbench profile, params.outdir is a gs:// path so results land in the
// workspace bucket.
process collectGreetings {
    publishDir "${params.outdir}", mode: 'copy'

    input:
    path greetings

    output:
    path 'COLLECTED-greetings.txt'

    script:
    """
    cat ${greetings} > COLLECTED-greetings.txt
    """
}
