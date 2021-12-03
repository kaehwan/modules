#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { CENTRIFUGE } from '../../../modules/centrifuge/main.nf' addParams( options: [args: '', suffix: '.centrifuge'] )

process CENTRIFUGE_DB_PREPARATION {
    conda (params.enable_conda ? "conda-forge::sed=4.7" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://containers.biocontainers.pro/s3/SingImgsRepo/biocontainers/v1.2.0_cv1/biocontainers_v1.2.0_cv1.img"
    } else {
        container "biocontainers/biocontainers:v1.2.0_cv1"
    }

    input:
    path db

    output:
    path "*.cf", emit: db

    script:
    """
    tar -xf "$db"
    """
}

workflow test_centrifuge_single_end {

    input = [ [ id:'test', single_end:true ], // meta map
              file(params.test_data['sarscov2']['illumina']['test_1_fastq_gz'], checkIfExists: true) ]
    db    = file('https://raw.githubusercontent.com/nf-core/test-datasets/mag/test_data/minigut_cf.tar.gz', checkIfExists: true)

    CENTRIFUGE_DB_PREPARATION ( db )
    CENTRIFUGE ( input, CENTRIFUGE_DB_PREPARATION.out.db )
}

workflow test_centrifuge_paired_end {

    input = [ [ id:'test', single_end:false ], // meta map
              [ file(params.test_data['sarscov2']['illumina']['test_1_fastq_gz'], checkIfExists: true),
                file(params.test_data['sarscov2']['illumina']['test_2_fastq_gz'], checkIfExists: true)]
            ]
    db    = file('https://raw.githubusercontent.com/nf-core/test-datasets/mag/test_data/minigut_cf.tar.gz', checkIfExists: true)

    CENTRIFUGE_DB_PREPARATION ( db )
    CENTRIFUGE ( input, CENTRIFUGE_DB_PREPARATION.out.db )
}
