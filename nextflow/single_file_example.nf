#!/usr/bin/env nextflow

// Pipeline parameters (can be overridden from the command line)
params.name = "World"

process WRITE_GREETING {
    // Specify the container image
    container 'ubuntu:latest'

    // Publish the output file to a final results directory
    publishDir 'results', mode: 'copy'

    input:
    val greet_name

    output:
    stdout emit: greeting
    path 'greeting.txt', emit: outfile

    script:
    """
    echo "Hello, ${greet_name}!" > greeting.txt
    cat greeting.txt
    """
}

workflow {
    // Create an input channel from the parameter
    name_ch = Channel.of(params.name)

    // Execute the process
    WRITE_GREETING(name_ch)

    // Print the captured stdout to the terminal
    WRITE_GREETING.out.greeting.view()
}
