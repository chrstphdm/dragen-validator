process CHECK_COPY_AND_FLAG{

    tag "${meta.dropbox_uuid}"

    label "process_medium_plus"

    publishDir "${params.taps_output_folder}/${meta.dropbox_uuid}",
        pattern: "*.tap", 
        mode: "copy", 
        failOnError: true

    publishDir "${params.rsync_logs_output_folder}",
        pattern: "*.rsync.log", 
        mode: "copy", 
        failOnError: true


    input:
        tuple   val(meta),
                val(DELIVERABLE_STATUS)

    output:
        tuple   val(meta),
                path("${meta.dropbox_uuid}.check_copy_and_flag.tap"),
                env(CHECK_COPY_AND_FLAG_STATUS), emit: tap_reports
        path("*.rsync.log"), optional: true, emit: rsync_log_files
                

    script:
    """
        ## \$1: dropbox_uuid_path
        ## \$2: target_folder - will copyt to target_folder/DROPBOX (& target_folder/)
        ## \$3: flag_file_to_create
        ## \$4: dry_mode ; (1 or empty)=true | 0=false

        if [ "${DELIVERABLE_STATUS}" == "ok" ]; then
            check_copy_and_flag.sh "${meta.dropbox_data_folder}" "${params.delivered_path}" "${params.my_org_flags_path}/${meta.dropbox_uuid}.DELIVERED" "${(params.dry ? 1 : 0)}" > ${meta.dropbox_uuid}.check_copy_and_flag.tap
        elif [ "${DELIVERABLE_STATUS}" == "nok" ]; then
            if [ ${(params.dry ? 1 : 0)} -eq 0 ]; then
                touch "${params.my_org_flags_path}/${meta.dropbox_uuid}.TO_REVIEW"
            fi
            echo "# Subtest: check_copy_and_flag" > ${meta.dropbox_uuid}.check_copy_and_flag.tap
            echo "    not ok 1 - ${meta.data_type} data cannot be delivered due to one or more previous errors. FLAG file TO_REVIEW have been created." >> ${meta.dropbox_uuid}.check_copy_and_flag.tap
            echo -e "    1..1" >> ${meta.dropbox_uuid}.check_copy_and_flag.tap
            echo -e "not ok - check_copy_and_flag${params.dry ? " # SKIP DRY-RUN":""}" >> ${meta.dropbox_uuid}.check_copy_and_flag.tap
        else
            echo "Current DELIVERABLE_STATUS value (${DELIVERABLE_STATUS}) is not supported. Please, contact the administrator."
            exit 1
        fi
        
        last_line=\$(tail -n 1 ${meta.dropbox_uuid}.check_copy_and_flag.tap)
        if [[ \$last_line == "ok - "* ]]; then
            CHECK_COPY_AND_FLAG_STATUS="ok"
        elif [[ \$last_line == "not ok - "* ]]; then
            CHECK_COPY_AND_FLAG_STATUS="nok"
        else
            echo "ERROR: output tap file is not correct. Contact the administrator."
            exit 1
        fi
    """
}