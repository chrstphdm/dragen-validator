process CHECK_DELIVERY_LIST_FORMAT{

    executor="local"

    publishDir "${params.dragen_validator_instance_path}", 
        mode: "copy", 
        failOnError: true

    input:
        path tsv_delivery_list

    output:
        path tsv_delivery_list

    script:
    """

    expected_header="TIMESTAMP\tACTION\tQBB_ID\tDROPBOX_UUID\tCASE_NUMBER\tMESSAGE\tCUSTOM MESSAGE\tDROPBOX_DATA_FOLDER"

    actual_header=\$(head -n 1 "${tsv_delivery_list}")

    if [[ "\${actual_header}" != "\${expected_header}" ]]; then
        echo "ERROR: delivery_list HEADER is not correct. Should contains [\${expected_header}]. Can not continue."
        exit 1
    fi

    """
}

process CHECK_DELIVERY_LIST_CONTENT{

    publishDir "${params.taps_output_folder}/${meta.dropbox_uuid}", 
        mode: "copy", 
        failOnError: true

    input:
        val(meta)

    output:
        tuple   val(meta),
                path("${meta.dropbox_uuid}.check_delivery_list.tap"), 
                env (CHECK_DELIVERY_LIST_CONTENT_STATUS)

    script:
    """
        nb_tests=0
        error_flag=0
        echo "# Subtest: check_delivery_list" > ${meta.dropbox_uuid}.check_delivery_list.tap
        
        ###############################################
        ## PROVIDER FLAGS verification
        (( nb_tests++ )) || true
        if [ ! -f "${params.provider_flags_path}/${meta.dropbox_uuid}.${meta.data_type}" ]; then
            echo "    not ok \${nb_tests} - Not an authentic ${meta.data_type} data : PROVIDER FLAG FILE is missing." >> ${meta.dropbox_uuid}.check_delivery_list.tap
            error_flag=1
        else
            echo "    ok \${nb_tests} - PROVIDER FLAG file ${meta.data_type} exists." >> ${meta.dropbox_uuid}.check_delivery_list.tap
        fi
        for value in "PASS" "LEGACY" "FORCED"; do
            (( nb_tests++ )) || true
            if [ "\$value" != "${meta.data_type}" ]; then
                if [ -f "${params.provider_flags_path}/${meta.dropbox_uuid}.\$value" ]; then
                    echo "    not ok \${nb_tests} - Not an authentic ${meta.data_type} data : FLAG FILE is missing." >> ${meta.dropbox_uuid}.check_delivery_list.tap
                    error_flag=1
                else
                    echo "    ok \${nb_tests} - FLAG file \$value does not exist." >> ${meta.dropbox_uuid}.check_delivery_list.tap
                fi
            fi
        done
        ###############################################
        ## DATA FOLDERS verification
        (( nb_tests++ )) || true
        if [ ! -d "${params.dropbox_path}/${meta.dropbox_uuid}" ]; then
            echo "    not ok \${nb_tests} - Not an authentic ${meta.data_type} data : DATA FOLDER is missing from DROPBOX." >> ${meta.dropbox_uuid}.check_delivery_list.tap
            error_flag=1
        else
            echo "    ok \${nb_tests} - DATA FOLDER exists in DROPBOX." >> ${meta.dropbox_uuid}.check_delivery_list.tap
        fi
        for dir in "${params.delivered_path}" "${params.rejected_path}"; do
            (( nb_tests++ )) || true
            if [ -d "\$dir/${params.dropbox_uuid}" ]; then
                echo "    not ok \${nb_tests} - Not an authentic ${meta.data_type} data : DATA FOLDER should not exists in \$dir." >> ${meta.dropbox_uuid}.check_delivery_list.tap
                error_flag=1
            else
                echo "    ok \${nb_tests} - DATA FOLDER does not exist in \$dir." >> ${meta.dropbox_uuid}.check_delivery_list.tap
            fi
        done
        ###############################################
        ## MY_ORG FLAGS verification
        for value in "DELIVERED" "REJECTED" "TO_REVIEW"; do
            (( nb_tests++ )) || true
            if [ -f "${params.my_org_flags_path}/${meta.dropbox_uuid}.\$value" ]; then
                echo "    not ok \${nb_tests} - Not an authentic ${meta.data_type} data : MY_ORG FLAG \$value should not exists." >> ${meta.dropbox_uuid}.check_delivery_list.tap
                error_flag=1
            else
                echo "    ok \${nb_tests} - MY_ORG FLAG file \$value does not exist." >> ${meta.dropbox_uuid}.check_delivery_list.tap
            fi
        done
        ###############################################
        echo "    1..\${nb_tests}"
        if [[ "\$error_flag" -eq 1 ]]; then
            echo "not ok - check_delivery_list" >> ${meta.dropbox_uuid}.check_delivery_list.tap
            CHECK_DELIVERY_LIST_CONTENT_STATUS="nok"
        else
            echo "ok - check_delivery_list" >> ${meta.dropbox_uuid}.check_delivery_list.tap
            CHECK_DELIVERY_LIST_CONTENT_STATUS="ok"
        fi
    """
}