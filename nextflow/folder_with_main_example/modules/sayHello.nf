#!/usr/bin/env nextflow

// Write a single greeting to its own file. One task runs per greeting, so this
// is where the pipeline fans out -- on the workbench profile each becomes an
// independent Google Batch job.
process sayHello {
    tag "${greeting}"

    input:
    val greeting

    output:
    path "${greeting}-output.txt"

    script:
    """
    echo '${greeting}' > '${greeting}-output.txt'
    """
}
