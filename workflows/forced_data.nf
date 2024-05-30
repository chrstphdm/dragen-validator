
include { CHECK_BASICS        } from '../modules/check_basics'
include { CHECK_METRICS       } from '../modules/check_sequencing_metrics'
include { CHECK_COPY_AND_FLAG } from '../modules/check_copy_and_flag'
include { GENERATE_TSV_REPORT } from '../modules/generate_reports'

process DELIVERABLE_STATUS_BEFORE_COPY {

    tag "${meta.dropbox_uuid}"

    input:
        tuple   val(meta),
                path(check_basics_tapfile), 
                env (CHECK_BASICS_STATUS),
                path(check_metrics_tapfile), 
                env (CHECK_METRICS_STATUS)
                
    output:
        tuple   val(meta),
                env(DELIVERABLE_STATUS)
    
    script:
    """
        if [[ \$CHECK_BASICS_STATUS == "ok" && \$CHECK_METRICS_STATUS == "ok" ]]; then
            DELIVERABLE_STATUS="ok"
        else
            DELIVERABLE_STATUS="nok"
        fi
    """
}

process MERGE_TAP_FILES {

    tag "${meta.dropbox_uuid}"

    publishDir "${params.taps_output_folder}", 
        mode: "copy", 
        failOnError: true

    input:
        tuple   val(meta),
                path(check_basics_tapfile), 
                env (CHECK_BASICS_STATUS),
                path(check_metrics_tapfile), 
                env (CHECK_METRICS_STATUS),
                path(check_copy_and_flag_tapfile), 
                env (CHECK_COPY_AND_FLAG_STATUS)
                
    output:
        tuple   val(meta),
                path("${meta.dropbox_uuid}.${meta.data_type}.*.tap"),
                env(DELIVERABLE_STATUS)
    script:
    """
        if [[ \$CHECK_BASICS_STATUS == "ok" && \$CHECK_METRICS_STATUS == "ok" && \$CHECK_COPY_AND_FLAG_STATUS == "ok" ]]; then
            DELIVERABLE_STATUS="ok"
        else
            DELIVERABLE_STATUS="nok"
        fi
        echo "TAP version 14" > ${meta.dropbox_uuid}.${meta.data_type}.\${DELIVERABLE_STATUS}.tap
        cat ${check_basics_tapfile} ${check_metrics_tapfile} ${check_copy_and_flag_tapfile} >> ${meta.dropbox_uuid}.${meta.data_type}.\${DELIVERABLE_STATUS}.tap
        echo "1..3" >> ${meta.dropbox_uuid}.${meta.data_type}.\${DELIVERABLE_STATUS}.tap
    """
}


workflow FORCED_DATA {
    take:
        delivery_data
    main:
        // launching the first checks
        CHECK_BASICS(delivery_data,1)
        CHECK_METRICS(delivery_data,1)
        // check for each data if it is deliverable or not
        DELIVERABLE_STATUS_BEFORE_COPY(CHECK_BASICS.out.join(CHECK_METRICS.out))
        // copying and flaging if possible
        CHECK_COPY_AND_FLAG(DELIVERABLE_STATUS_BEFORE_COPY.out)
        // merging all the tap files from first checks and copy_flag step
        MERGE_TAP_FILES(CHECK_BASICS.out.join(CHECK_METRICS.out.join(CHECK_COPY_AND_FLAG.out.tap_reports)))
        // generate a TSV to resume everything
        GENERATE_TSV_REPORT(MERGE_TAP_FILES.out)
    emit:
        tap_reports = MERGE_TAP_FILES.out
        tsv_reports = GENERATE_TSV_REPORT.out.summary_reports
}