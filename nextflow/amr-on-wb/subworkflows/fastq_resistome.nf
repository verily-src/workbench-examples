// Load modules
include { index ; bwa_align } from '../modules/Alignment/bwa'

// resistome
include {plotrarefaction ; runresistome ; runsnp ; resistomeresults ; runrarefaction ; snpresults} from '../modules/Resistome/resistome'

// Deduped resistome
include { BAM_DEDUP_RESISTOME_WF } from '../subworkflows/bam_deduped_resistome.nf'

import java.nio.file.Paths

workflow FASTQ_RESISTOME_WF {
    take: 
        read_pairs_ch
        amr
        annotation

    main:
        // Use pre-built binaries from container
        amrsnp = file("${baseDir}/bin/AmrPlusPlus_SNP")
        resistomeanalyzer = file("${baseDir}/bin/resistome")
        rarefactionanalyzer = file("${baseDir}/bin/rarefaction")
        // Define amr_index_files variable
        if (params.amr_index == null) {
            index(amr)
            amr_index_files = index.out
        } else {
            amr_index_files = Channel
                .fromPath(Paths.get(params.amr_index))
                .map { file(it.toString()) }
                .filter { file(it).exists() }
                .toList()
                .map { files ->
                    if (files.size() < 6) {
                        error "Expected 6 AMR index files, found ${files.size()}. Please provide all 6 files, including the AMR database fasta file. Remember to use * in your path."
                    } else {
                        files.sort()
                    }
                }
         }        
        // AMR alignment
        bwa_align(amr_index_files, read_pairs_ch )
        // Split sections below for standard and dedup_ed results
        runresistome(bwa_align.out.bwa_bam,amr, annotation, resistomeanalyzer )
        resistomeresults(runresistome.out.resistome_counts.collect())
        runrarefaction(bwa_align.out.bwa_bam, annotation, amr, rarefactionanalyzer)
        plotrarefaction(runrarefaction.out.rarefaction.collect())
        // Add SNP confirmation
        if (params.snp == "Y") {
            runsnp(bwa_align.out.bwa_bam, resistomeresults.out.snp_count_matrix, amrsnp)
            snpresults(runsnp.out.snp_counts.collect() )
        }
        // Add analysis of deduped counts
        if (params.deduped == "Y"){
            BAM_DEDUP_RESISTOME_WF(bwa_align.out.bwa_dedup_bam,amr, annotation)
        }
}


