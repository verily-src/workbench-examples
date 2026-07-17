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
 *   nextflow run main.nf -profile workbench                # Google Batch (see README)
 */

include { sayHello }         from './modules/sayHello.nf'
include { convertToUpper }   from './modules/convertToUpper.nf'
include { collectGreetings } from './modules/collectGreetings.nf'

workflow {
    // On Workbench, results must go to a bucket. A relative outdir is written to
    // the ephemeral orchestrator disk and lost (the only durable copy ends up
    // buried in the work dir), yet the run still reports success -- so fail fast
    // instead. Reference the bucket by its resource, not a hardcoded name.
    if (workflow.profile.contains('workbench') && !"${params.outdir}".startsWith('gs://')) {
        error "On -profile workbench, set outdir to a gs:// path, e.g.\n" +
              "  --outdir \"\$(wb resource resolve --name=nf-scratch)/hello-nf-on-wb/results\"\n" +
              "(or set it in your params file). See README."
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
