process CHECK_BASICS{

    tag "${meta.dropbox_uuid}"

    publishDir "${params.taps_output_folder}/${meta.dropbox_uuid}", 
        mode: "copy", 
        failOnError: true

    label 'process_medium_plus'

    input:
        val(meta)
        val(skip_optionnals)

    output:
        tuple   val(meta),
                path("${meta.dropbox_uuid}.check_basics.tap"), 
                env (CHECK_BASICS_STATUS)

    script:
    """
        check_basics.sh "${meta.dropbox_data_folder}" "${meta.qbb_id}" "${skip_optionnals}" > ${meta.dropbox_uuid}.check_basics.tap
        last_line=\$(tail -n 1 ${meta.dropbox_uuid}.check_basics.tap)
        if [[ \$last_line == "ok - "* ]]; then
            CHECK_BASICS_STATUS="ok"
        elif [[ \$last_line == "not ok - "* ]]; then
            CHECK_BASICS_STATUS="nok"
        else
            echo "ERROR: output tap file is not correct. Contact the administrator."
            exit 1
        fi
    """
}