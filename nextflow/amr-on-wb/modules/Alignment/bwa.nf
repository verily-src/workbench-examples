include { reference_error ; amr_error ; annotation_error } from "$baseDir/modules/nf-functions.nf"


if( params.amr ) {
    amr = file(params.amr)
    if( !amr.exists() ) return amr_error(amr)
}
if( params.annotation ) {
    annotation = file(params.annotation)
    if( !annotation.exists() ) return annotation_error(annotation)
}


threads = params.threads

deduped = params.deduped

process index {
    tag "Creating bwa index"
    label "alignment"

    errorStrategy { task.exitStatus in 137..140 ? 'retry' : 'terminate' }
    maxRetries 3

    publishDir "${params.output}/Alignment/BWA_Index", mode: "copy"

    input:
    path fasta

    output: 
    path("${fasta}*"), emit: bwaindex, includeInputs: true

    script:
    """
    bwa index ${fasta}
    #--threads $task.cpus 
    """
}


process bwa_align {
    tag "$pair_id"
    label "alignment"

    errorStrategy { task.exitStatus in 137..140 ? 'retry' : 'terminate' }
    maxRetries 3

    publishDir "${params.output}/Alignment/BAM_files", mode: "copy",
        saveAs: { filename ->
            if(filename.indexOf("_alignment_sorted.bam") > 0) "Standard/$filename"
            else if(filename.indexOf("_alignment_dedup.bam") > 0) "Deduped/$filename"
            else {}
        }

    input:
        path indexfiles
        tuple val(pair_id), path(reads)

    output:
        tuple val(pair_id), path("${pair_id}_alignment_sorted.bam"), emit: bwa_bam
        tuple val(pair_id), path("${pair_id}_alignment_dedup.bam"), emit: bwa_dedup_bam, optional: true

    script:
    if( deduped == "N")
        """
        ${BWA} mem ${indexfiles[0]} ${reads} -t ${task.cpus} -R '@RG\\tID:${pair_id}\\tSM:${pair_id}' > ${pair_id}_alignment.sam
        ${SAMTOOLS} view -@ ${task.cpus} -S -b ${pair_id}_alignment.sam > ${pair_id}_alignment.bam
        rm ${pair_id}_alignment.sam
        ${SAMTOOLS} sort -@ ${task.cpus} -n ${pair_id}_alignment.bam -o ${pair_id}_alignment_sorted.bam
        rm ${pair_id}_alignment.bam
        """
    else if( deduped == "Y")
        """
        ${BWA} mem ${indexfiles[0]} ${reads} -t ${task.cpus} -R '@RG\\tID:${pair_id}\\tSM:${pair_id}' > ${pair_id}_alignment.sam
        ${SAMTOOLS} view -@ ${task.cpus} -S -b ${pair_id}_alignment.sam > ${pair_id}_alignment.bam
        rm ${pair_id}_alignment.sam
        ${SAMTOOLS} sort -@ ${task.cpus} -n ${pair_id}_alignment.bam -o ${pair_id}_alignment_sorted.bam
        rm ${pair_id}_alignment.bam
        ${SAMTOOLS} fixmate -@ ${task.cpus} ${pair_id}_alignment_sorted.bam ${pair_id}_alignment_sorted_fix.bam
        ${SAMTOOLS} sort -@ ${task.cpus} ${pair_id}_alignment_sorted_fix.bam -o ${pair_id}_alignment_sorted_fix.sorted.bam
        rm ${pair_id}_alignment_sorted_fix.bam
        ${SAMTOOLS} rmdup -S ${pair_id}_alignment_sorted_fix.sorted.bam ${pair_id}_alignment_dedup.bam
        rm ${pair_id}_alignment_sorted_fix.sorted.bam
        ${SAMTOOLS} view -@ ${task.cpus} -h -o ${pair_id}_alignment_dedup.sam ${pair_id}_alignment_dedup.bam
        rm ${pair_id}_alignment_dedup.sam
        """
    else
        error "Invalid deduplication flag --deduped: ${deduped}. Please use --deduped Y for deduplicated counts, or avoid using this flag altogether to skip this error."
}

process bwa_rm_contaminant_fq {
    tag { pair_id }
    label "alignment"

    errorStrategy { task.exitStatus in 137..140 ? 'retry' : 'terminate' }
    maxRetries 3

    publishDir "${params.output}/HostRemoval", mode: "copy",
        saveAs: { filename ->
            if(filename.indexOf("fastq.gz") > 0) "NonHostFastq/$filename"
            else {}
        }

    input:
    path indexfiles
    tuple val(pair_id), path(reads)

    output:
    tuple val(pair_id), path("${pair_id}.non.host.R*.fastq.gz"), emit: nonhost_reads
    path("${pair_id}.samtools.idxstats"), emit: host_rm_stats

    """
    ${BWA} mem ${indexfiles[0]} ${reads[0]} ${reads[1]} -t ${task.cpus} > ${pair_id}.host.sam
    ${SAMTOOLS} view -bS ${pair_id}.host.sam | ${SAMTOOLS} sort -@ ${task.cpus} -o ${pair_id}.host.sorted.bam
    rm ${pair_id}.host.sam
    ${SAMTOOLS} index ${pair_id}.host.sorted.bam && ${SAMTOOLS} idxstats ${pair_id}.host.sorted.bam > ${pair_id}.samtools.idxstats
    ${SAMTOOLS} view -h -f 12 -b ${pair_id}.host.sorted.bam -o ${pair_id}.host.sorted.removed.bam
    ${SAMTOOLS} sort -n -@ ${task.cpus} ${pair_id}.host.sorted.removed.bam -o ${pair_id}.host.resorted.removed.bam
    ${SAMTOOLS}  \
       fastq -@ ${task.cpus} -c 6  \
      ${pair_id}.host.resorted.removed.bam \
      -1 ${pair_id}.non.host.R1.fastq.gz \
      -2 ${pair_id}.non.host.R2.fastq.gz \
      -0 /dev/null -s /dev/null -n

    rm *.bam
    """

}

process HostRemovalStats {
    tag { sample_id }
    label "alignment"

    errorStrategy { task.exitStatus in 137..140 ? 'retry' : 'terminate' }
    maxRetries 3 

    publishDir "${params.output}/Results", mode: "copy",
        saveAs: { filename ->
            if(filename.indexOf(".stats") > 0) "Stats/$filename"
        }

    input:
        file(host_rm_stats)

    output:
        path("host.removal.stats"), emit: combo_host_rm_stats

    """
    ${PYTHON3} /opt/amrplusplus/bin/samtools_idxstats.py -i ${host_rm_stats} -o host.removal.stats
    """
}
