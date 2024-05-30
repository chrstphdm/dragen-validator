process CHECK_LEGACY{

    tag "${meta.dropbox_uuid}"
    
    publishDir "${params.taps_output_folder}/${meta.dropbox_uuid}", 
        mode: "copy", 
        failOnError: true

    input:
        val(meta)

    output:
        tuple   val(meta),
                path("${meta.dropbox_uuid}.check_legacy.tap"), 
                env (CHECK_LEGACY_STATUS)

    script:
    """
        check_legacy.sh "${meta.dropbox_data_folder}" "${meta.qbb_id}" > ${meta.dropbox_uuid}.check_legacy.tap
        last_line=\$(tail -n 1 ${meta.dropbox_uuid}.check_legacy.tap)
        if [[ \$last_line == "ok - "* ]]; then
            CHECK_LEGACY_STATUS="ok"
        elif [[ \$last_line == "not ok - "* ]]; then
            CHECK_LEGACY_STATUS="nok"
        else
            echo "ERROR: output tap file is not correct. Contact the administrator."
            exit 1
        fi
    """
}