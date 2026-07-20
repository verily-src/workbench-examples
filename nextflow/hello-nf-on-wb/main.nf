#!/usr/bin/env nextflow

/*
 * hello-nf-on-wb
 *
 * A minimal Nextflow pipeline, in the style of the official Nextflow "Hello"
 * training (https://training.nextflow.io), that runs unchanged on your laptop
 * or on Verily Workbench via Google Batch.
 *
 * The pipeline reads greetings from a CSV, writes each to its own file,
 * uppercases them in parallel, and collects them into one result. The point is
 * not the string processing -- it is to show a Workbench-ready pipeline
 * (profiles, params, containers, a GCS work directory) with no domain noise.
 *
 * Run it:
 *   nextflow run main.nf -profile standard                 # local, no container
 *   nextflow run main.nf -profile standard -params-file test-params.yaml
 *   wb nextflow run main.nf -profile verily_workbench      # Google Batch (see README)
 */

include { sayHello }         from './modules/sayHello.nf'
include { convertToUpper }   from './modules/convertToUpper.nf'
include { collectGreetings } from './modules/collectGreetings.nf'

workflow {
    // On Workbench, both the output and work dirs must be gs:// buckets. A
    // relative path is written to the ephemeral orchestrator disk and lost (the
    // durable copy ends up buried in the work dir), yet the run still reports
    // success -- so fail fast instead. Reference the bucket by its resource, not
    // a hardcoded name. workflow.workDir is the *resolved* work dir, so this
    // passes on the UI (which sets it for you) and catches a missing --work_dir
    // on the CLI.
    if (workflow.profile.contains('verily_workbench')) {
        if (!"${params.outdir}".startsWith('gs://')) {
            error "On -profile verily_workbench, set outdir to a gs:// path, e.g.\n" +
                  "  --outdir \"\$(wb resource resolve --name=<your-bucket-resource>)/hello-nf-on-wb/results\"\nSee README."
        }
        // Use .scheme, not string interpolation -- a remote Path renders as just
        // its object key ("/scratch") in a GString, losing the gs:// prefix.
        if (workflow.workDir.scheme != 'gs') {
            error "On -profile verily_workbench, the work dir must be a gs:// path.\n" +
                  "  CLI: --work_dir \"\$(wb resource resolve --name=<your-bucket-resource>)/scratch\"\n" +
                  "  UI:  set for you automatically.\nSee README."
        }
    }

    // One item per CSV row (first column) -> the source of the fan-out.
    greeting_ch = Channel.fromPath(params.input)
                         .splitCsv()
                         .map { row -> row[0] }

    sayHello(greeting_ch)
    convertToUpper(sayHello.out)
    collectGreetings(convertToUpper.out.collect())

    collectGreetings.out.view { result -> "Collected greetings: ${result}" }
}
