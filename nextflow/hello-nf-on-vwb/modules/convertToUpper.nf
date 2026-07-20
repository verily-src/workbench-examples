#!/usr/bin/env nextflow

// Uppercase one greeting file. Runs in parallel across all greetings.
process convertToUpper {
    tag "${input_file}"

    input:
    path input_file

    output:
    path "UPPER-${input_file}"

    script:
    """
    cat '${input_file}' | tr '[:lower:]' '[:upper:]' > 'UPPER-${input_file}'
    """
}
