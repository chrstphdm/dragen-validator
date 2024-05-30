#!/usr/bin/gawk -f

############################################################
# DESCRIPTION
## Generate a TSV file from a TAP file.
## Only get the subtests names and results from the TAP file.
#
# INPUT VARIABLES
## timestamp
## data_type
## qbb_id
## dropbox_uuid
## deliverable_status
#
# OUTPUT
## stdout: TSV formatted output
############################################################

BEGIN{
    FS=" "
    OFS="\t"
    error_flag=""

    if (timestamp == ""){
        error_flag = error_flag "ERROR: timestamp variable is MANDATORY.\n"
    }
    if (data_type == ""){
        error_flag = error_flag "ERROR: data_type variable is MANDATORY.\n"
    }
    if (dropbox_uuid == ""){
        error_flag = error_flag "ERROR: dropbox_uuid variable is MANDATORY.\n"
    }
    if (qbb_id == ""){
        error_flag = error_flag "ERROR: qbb_id variable is MANDATORY.\n"
    }
    if (deliverable_status == ""){
        error_flag = error_flag "ERROR: deliverable_status variable is MANDATORY.\n"
    }

    if(error_flag != "") exit 1
    
    tests[1]="check_basics"
    tests[2]="check_legacy"
    tests[3]="check_sequencing_metrics"
    tests[4]="check_copy_and_flag"
} 
$0 ~ /^(ok|not ok)/{
    delete arr
    match($0, /(ok|not ok) - (\w+)( # SKIP| # SKIP DRY-RUN)?/, arr)
    data[arr[2]]=arr[1]arr[3]
} 
END{
    if(error_flag != "" ){
        printf "%s", error_flag > "/dev/stderr"
        exit 1
    }

    print "TIMESTAMP\tDATA_TYPE\tQBB_ID\tDROPBOX_UUID\tDELIVERABLE_STATUS\tCHECK_BASICS_STATUS\tCHECK_LEGACY_STATUS\tCHECK_SEQUENCING_METRICS_STATUS\tCHECK_COPY_AND_FLAG_STATUS"; 
    printf "%s\t%s\t%s\t%s\t%s",timestamp,data_type,qbb_id,dropbox_uuid,deliverable_status
    for (i=1;i<=length(tests);i++){
        if(tests[i] in data)
            printf "\t%s",data[tests[i]]
        else
            printf "\tNA"
    }
    print ""
}