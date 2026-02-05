// resistome counts and snp verification
include {plotrarefaction ; runresistome ; runsnp ; resistomeresults ; snpresults} from '../modules/Resistome/resistome'


workflow BAM_RESISTOME_COUNTS_WF {
    take: 
        bam_ch
        amr
        annotation

    main:
        // Use pre-built binaries from container
        amrsnp = file("${baseDir}/bin/AmrPlusPlus_SNP")
        resistomeanalyzer = file("${baseDir}/bin/resistome")
        // Split sections below for standard and dedup_ed results
        runresistome(bam_ch,amr, annotation, resistomeanalyzer )
        resistomeresults(runresistome.out.resistome_counts.collect())
        // Add SNP confirmation
        if (params.snp == "Y") {
            runsnp(bam_ch, resistomeresults.out.snp_count_matrix, amrsnp)
            snpresults(runsnp.out.snp_counts.collect())
        }
}


