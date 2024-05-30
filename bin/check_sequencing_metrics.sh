#!/bin/bash

############################################################
# DESCRIPTION
## Check dragen QC metrics and print TAP formatted results.
## Can add "# SKIP" directive if asked. 
#
# INPUT
## $1: dropbox_uuid_path
## $2: sample_id
## $3: is_skipped ; 1=true | (0 or empty)=false
#
# OUTPUT
## stdout: TAP formatted output
############################################################

module load samtools/v1.18

check_folder() {
    (( nb_tests++ )) || true
    if [ -d "$1" ] ; then
        echo -e "    ok ${nb_tests} - $2 folder exists"
        (( nb_tests++ )) || true
        if [ -r "$1" ] ; then
            echo -e "    ok ${nb_tests} - $2 folder readable"
        else
            echo -e "    not ok ${nb_tests} - $2 folder is not readable"
            flag_ok=0
        fi
    else
        echo -e "    not ok ${nb_tests} - $2 folder does not exist"
        flag_ok=0
    fi
}

check_file_existence() {
    (( nb_tests++ )) || true
    if [[ ! -e "$1" ]]; then
        echo -e "    not ok ${nb_tests} - $2 file is missing"
        flag_ok=0
    else
        echo -e "    ok ${nb_tests} - $2 file exists"
    fi
}

check_pattern_file_existence() {
    (( nb_tests++ )) || true
    directory="$1"
    matching_files=$(find "$directory" -maxdepth 1 -type f -name "$2")

    if [[ -z $matching_files ]]; then
        echo -e "    not ok ${nb_tests} - No file matching $2 found"
        flag_ok=0
    else
        echo -e "    ok ${nb_tests} - File(s) matching $2 exist(s)"
    fi
}


check_file_content() {
    (( nb_tests++ )) || true
    if [[ ! -s "$1" ]]; then
        echo -e "    not ok ${nb_tests} - $2 file is empty"
        flag_ok=0
    else
        echo -e "    ok ${nb_tests} - $2 file is not empty"
    fi
}

check_sample_id_in_cram() {
    (( nb_tests++ )) || true
    if [[ $(samtools view -H "$1" | grep -c -P "^@RG.*SM:$2") -eq 0 ]]; then
        echo -e "    not ok ${nb_tests} - cram file does not contain correct sample_id as 'SM:' field"
        flag_ok=0
    else
        echo -e "    ok ${nb_tests} - cram file contains correct sample_id as 'SM:' field"
    fi
}

check_value_condition() {
    (( nb_tests++ )) || true
    if [ "$(echo "${1} ${2}" | bc)" -eq 1 ]; then
        echo -e "    ok ${nb_tests} - $3 : [${1}] is [${2}]"
    else
        echo -e "    not ok ${nb_tests} - $3 : [${1}] is not [${2}]"
        flag_ok=0
    fi
}


## Main script
current_test_name=$(basename "$0" .sh)
dropbox_uuid_path="${1}"
sample_id="${2}"
is_skipped="${3}"

flag_ok=1
nb_tests=0

if [[ "${is_skipped}" -eq 1 ]]; then
    is_skipped="# SKIP"
else
    is_skipped=""
fi

echo -e "# Subtest: ${current_test_name}"

PCT_DUP=$(grep "^MAPPING/ALIGNING SUMMARY" "$dropbox_uuid_path/$sample_id.mapping_metrics.csv" | cut -d, -f3,5 | grep "Number of duplicate marked reads"| sed 's/Number of duplicate marked reads,//g')
AVG_COV=$(head -n1 "$dropbox_uuid_path/$sample_id.wgs_overall_mean_cov.csv" | grep -oE "[0-9]+\.[0-9]+")
FIFTEENX=$(grep "^COVERAGE SUMMARY" "$dropbox_uuid_path/$sample_id.wgs_coverage_metrics.csv" | cut -d, -f3,4 | grep "15x: inf"| cut -d, -f2)
INSERT=$(grep "^MAPPING/ALIGNING SUMMARY" "$dropbox_uuid_path/$sample_id.mapping_metrics.csv" | cut -d, -f3,4 | grep "Insert length: median" | sed 's/Insert length: median,//g')

check_value_condition "${PCT_DUP}" "< 20"  "Pourcentage of reads duplicates"
check_value_condition "${AVG_COV}" ">= 30" "MEAN coverage over genome"
check_value_condition "${FIFTEENX}" ">= 90" "Pourcentage of genome with coverage >=15X"
check_value_condition "${INSERT}" ">= 250" "Median Insert length"



echo -e "    1..${nb_tests}"
if [[ "$flag_ok" -eq 1 ]]; then
    echo -e "ok - ${current_test_name} ${is_skipped}"
else
    echo -e "not ok - ${current_test_name} ${is_skipped}"
fi






