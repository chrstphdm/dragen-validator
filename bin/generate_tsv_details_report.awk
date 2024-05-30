#!/usr/bin/gawk -f

############################################################
# DESCRIPTION
## Generate a TSV file from a TAP file.
## Only get the results of each tests in subtests.
#
# INPUT VARIABLES
## qbb_id
## dropbox_uuid
#
# OUTPUT
## stdout: TSV formatted output
############################################################
BEGIN{
    error_flag=""
    FS=" "
    OFS="\t"

    if (dropbox_uuid == ""){
        error_flag = error_flag "ERROR: dropbox_uuid variable is MANDATORY.\n"
    }
    if (qbb_id == ""){
        error_flag = error_flag "ERROR: qbb_id variable is MANDATORY.\n"
    }

    if(error_flag != "") exit 1
    
    tests[1]="check_basics"; 
    tests[2]="check_legacy"; 
    tests[3]="check_sequencing_metrics"
    tests[4]="check_copy_and_flag"
}
$0 ~ /^# Subtest:/{
    delete arr
    match($0,/# Subtest: (.*)/,arr)
    current_subtest=arr[1]
    delete subtest_data[current_subtest]["SUBSUBTESTS"][0]
}
$0 ~ /^    (ok|not ok)/{
    delete arr
    match($0, /^    (ok|not ok) ([[:digit:]]+)+ - (.*)/, arr)
    subtest_data[current_subtest]["SUBSUBTESTS"][arr[2]]["STATUS"]=arr[1]
    subtest_data[current_subtest]["SUBSUBTESTS"][arr[2]]["MESSAGE"]=arr[3]
}
$0 ~ /^(ok|not ok)/{
    delete arr
    match($0, /(ok|not ok) - (\w+)( # SKIP)?/, arr)
    subtest_data[current_subtest]["IS_SKIPPED"]=arr[3] ~ / # SKIP/?1:0
}

END{
    if(error_flag != "" ){
        printf "%s", error_flag > "/dev/stderr"
        exit 1
    }

    print "QBB_ID\tDROPBOX_UUID\tTEST_NAME\tSUBTEST_NUMBER\tSUBTEST_IS_SKIPPED\tSUBTEST_STATUS\tSUBTEST_MESSAGE"; 
    for (i=1;i<=4;i++){
        if (tests[i] in subtest_data && "SUBSUBTESTS" in subtest_data[tests[i]]){
            size=length(subtest_data[tests[i]]["SUBSUBTESTS"])
            for(j=1;j<=size;j++){
                printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n",qbb_id,dropbox_uuid,tests[i],j,subtest_data[tests[i]]["IS_SKIPPED"],subtest_data[tests[i]]["SUBSUBTESTS"][j]["STATUS"],subtest_data[tests[i]]["SUBSUBTESTS"][j]["MESSAGE"]
            }
        }
    }
}