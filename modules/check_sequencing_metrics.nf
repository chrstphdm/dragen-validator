process CHECK_METRICS{

    tag "${meta.dropbox_uuid}"
    
    publishDir "${params.taps_output_folder}/${meta.dropbox_uuid}", 
        mode: "copy", 
        failOnError: true

    input:
        val(meta)
        val(is_skipped)

    output:
        tuple   val(meta),
                path("${meta.dropbox_uuid}.check_sequencing_metrics.tap"), 
                env (CHECK_METRICS_STATUS)

    script:
    """
        check_sequencing_metrics.sh "${meta.dropbox_data_folder}" "${meta.qbb_id}" "${is_skipped}" > ${meta.dropbox_uuid}.check_sequencing_metrics.tap
        last_line=\$(tail -n 1 ${meta.dropbox_uuid}.check_sequencing_metrics.tap)
        if [[ \$last_line == "ok - "* || ${is_skipped} -eq 1 ]]; then
            CHECK_METRICS_STATUS="ok"
        elif [[ \$last_line == "not ok - "* ]]; then
            CHECK_METRICS_STATUS="nok"
        else
            echo "ERROR: output tap file is not correct. Contact the administrator."
            exit 1
        fi
    """
}