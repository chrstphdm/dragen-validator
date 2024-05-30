#!/bin/bash

############################################################
# DESCRIPTION
## 
##
##
#
# INPUT
## $1: dropbox_uuid_path
## $2: sample_id
#
# OUTPUT
## stdout: TAP formatted output
############################################################

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

## Main script
current_test_name=$(basename "$0" .sh)
dropbox_uuid_path="${1}"
flag_ok=1
nb_tests=0

echo -e "# Subtest: ${current_test_name}"
check_folder "${dropbox_uuid_path}/old_qc" "old_qc"
echo -e "    1..${nb_tests}"
if [[ "$flag_ok" -eq 1 ]]; then
    echo -e "ok - ${current_test_name}"
else
    echo -e "not ok - ${current_test_name}"
fi
