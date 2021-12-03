// Import generic module functions
include { initOptions; saveFiles; getSoftwareName; getProcessName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process CENTRIFUGE {
    tag "$meta.id"
    label 'process_medium'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), meta:meta, publish_by_meta:['id']) }

    conda (params.enable_conda ? "bioconda::centrifuge=1.0.4_beta" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/centrifuge:1.0.4_beta--he513fc3_5"
    } else {
        container "quay.io/biocontainers/centrifuge:1.0.4_beta--he513fc3_5"
    }

    input:
    tuple val(meta), path(reads)
    path db

    output:
    tuple val("centrifuge"), val(meta), path("*.results.krona"), emit: results_for_krona
    path "*.report.txt"                                        , emit: report
    path "*.kreport.txt"                                       , emit: kreport
    path "versions.yml"                                        , emit: versions

    script:
    def prefix = options.suffix ? "${meta.id}${options.suffix}" : "${meta.id}"
    def input  = meta.single_end ? "-U \"${reads}\"" :  "-1 \"${reads[0]}\" -2 \"${reads[1]}\""
    def db_name = db.first().getName().replace(".1.cf", "")

    """
    centrifuge \\
        -x "$db_name" \\
        -p $task.cpus \\
        --report-file ${prefix}.report.txt \\
        -S ${prefix}.results.txt \\
        $options.args \\
        $input
    centrifuge-kreport -x "$db_name" ${prefix}.results.txt > ${prefix}.kreport.txt
    cat ${prefix}.results.txt | cut -f 1,3 > ${prefix}.results.krona

    cat <<-END_VERSIONS > versions.yml
    ${getProcessName(task.process)}:
        ${getSoftwareName(task.process)}: \$( centrifuge --version | head -n 1 | sed 's/^.*centrifuge-class version //' )
    END_VERSIONS
    """
}
