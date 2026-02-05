// Deduped functions with prefix for name
include {runresistome as runresistome_dedup ; runsnp as runsnp_dedup; resistomeresults as resistomeresults_dedup ; snpresults as snpresults_dedup} from '../modules/Resistome/resistome' addParams(prefix: 'dedup_AMR')


workflow BAM_DEDUP_RESISTOME_WF {
    take: 
        bam_ch
        amr
        annotation

    main:
        // Use pre-built binaries from container
        amrsnp = file("${baseDir}/bin/AmrPlusPlus_SNP")
        resistomeanalyzer = file("${baseDir}/bin/resistome")
        rarefactionanalyzer = file("${baseDir}/bin/rarefaction")
        runresistome_dedup(bam_ch,amr, annotation, resistomeanalyzer )
        resistomeresults_dedup(runresistome_dedup.out.resistome_counts.collect())
        if (params.snp == "Y") {
            runsnp_dedup(bam_ch, resistomeresults_dedup.out.snp_count_matrix, amrsnp)
            snpresults_dedup(runsnp_dedup.out.snp_counts.collect())
        }
}


