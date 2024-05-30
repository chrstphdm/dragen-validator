#!/bin/bash

############################################################
# DESCRIPTION
## Check dropbox_uuid_path & target_folder existence.
## Copy dropbox_uuid_path to target_folder and create flag_file_to_create is everything is OK.
## Depending of the dry-mode value, save the rsync logs as :
##  ${dropbox_uuid}.rsync.log OR ${dropbox_uuid}.rsync.dry-run.log
## add # SKIP DRY-RUN in output if dry_mode used and user dry-run in the rsyncs
#
# INPUT
## $1: dropbox_uuid_path
## $2: target_folder
## $3: flag_file_to_create
## $4: dry_mode ; (1 or empty)=true | 0=false
#
# OUTPUT
## stdout: TAP formatted output
############################################################

print_message() {
    status="${1}"
    message="${2}"

    (( nb_tests++ )) || true
    echo -e "    ${status} ${nb_tests} - ${message}"
    if [ "${status}" == "not ok" ]; then
        flag_ok=0
    fi
}

check_folder() {
    folder_path="${1}"
    folder_name="${2}"

    if [ -d "${folder_path}" ] ; then
        print_message "ok" "${folder_name} folder exists"
        if [ -r "${folder_path}" ] ; then
            print_message "ok" "${folder_name} folder readable"
        else
            print_message "not ok" "${folder_name} folder is not readable"
        fi
    else
        print_message "not ok" "${folder_name} folder does not exist"
    fi
}

check_md5sum() {
    md5_filepath="${1}"
    md5_filename="$(basename "${md5_filepath}")"

    if [[ ! -e "${md5_filepath}" ]]; then
        print_message "not ok" "${md5_filename} md5sum file does not exists"
    else
        normal_filepath="$(dirname "${md5_filepath}")/$(basename "${md5_filepath}" .md5sum)"
        if [[ ! -e "${normal_filepath}" ]]; then
            print_message "not ok" "${normal_filepath} file does not exists, md5sum can not be checked"
        else
            md5_stdout=$(echo "$(cat "${md5_filepath}") ${normal_filepath}" | md5sum -c - 2>/dev/null)
            # shellcheck disable=SC2181
            if [[ $? -ne 0 ]]; then
                print_message "not ok" "${md5_filename} md5sum can not be checked"
            fi
            echo "${md5_stdout}" | awk 'BEGIN{FS="(: |/)"}$NF ~ /OK|FAILED/{ if($NF == "OK") exit 0; else exit 1; }' -
            # shellcheck disable=SC2181
            if [[ $? -ne 0 ]]; then
                print_message "not ok" "${md5_filename} md5sum check is not correct"
            else
                print_message "ok" "${md5_filename} md5sum check is correct"
            fi
        fi
    fi
}

run_rsync_and_flag() {
    local source_folder="${1}" 
    local target_folder="${2}"
    local source_foldername="${3}"
    local flag_filepath="${4}"
    ###################################################
    # shellcheck disable=SC2155
    local flag_filename="$(basename "${flag_filepath}")"
    # shellcheck disable=SC2155
    local source_folder_basename=$(basename "$source_folder")
    target_source_folder_path="$target_folder/$source_folder_basename"
    ###################################################
    # check if a flag already eixsts
    flag_file_pattern="${flag_filepath%.*}"
    if ls "${flag_file_pattern}".* 1> /dev/null 2>&1; then
        print_message "not ok" "a FLAG_FILE already exists"
    else
        print_message "ok" "rsync can process because no FLAG_FILE exists"
        local rsync_opts=(--times --recursive --quiet -vv --chmod=550)
        local log_suffix=".rsync.log"

        if [ "${dry_mode}" -eq 1 ]; then
            rsync_opts=(--dry-run --times --recursive --quiet -vv --chmod=550)
            log_suffix=".dry-run.rsync.log"
        fi

        echo "RUNNING rsync " "${rsync_opts[@]}" "${source_folder}" "${target_folder} --log-file ${source_foldername}${log_suffix}" > "${source_foldername}${log_suffix}"
        rsync "${rsync_opts[@]}" "${source_folder}" "${target_folder}" --log-file "${source_foldername}${log_suffix}"

        if [ $? -eq 0 ]; then
            print_message "ok" "rsync execution for [${source_foldername}] to [$(basename "${target_folder}")] is correct ${is_skipped}"

            if [ "${dry_mode}" -ne 1 ]; then
                touch "${flag_filepath}"
                if [ $? -eq 0 ]; then
                    print_message "ok" "flag file [${flag_filename}] has been created ${is_skipped}"
                else
                    print_message "not ok" "flag file [${flag_filename}] has not been created ${is_skipped}"
                fi
            fi

            ###################################################
            # the following will throw an error in dry-mode, but is_skipped will be true
            chgrp -R g_MY_ORG "${target_source_folder_path}"
            if [ $? -eq 0 ]; then
                print_message "ok" "chgrp -R g_MY_ORG on [${source_folder_basename}] is correct ${is_skipped}"
            else
                print_message "not ok" "chgrp -R g_MY_ORG on [${source_folder_basename}] is not correct ${is_skipped}"
            fi
        else
            print_message "not ok" "rsync execution for [${source_foldername}] to [$(basename "${target_folder}")] is not correct${is_skipped}"
        fi
    fi
}




## Main script
flag_ok=1 # Default is 
nb_tests=0
is_skipped=""

dropbox_uuid_path="${1}"
target_folder="${2}"
flag_file_to_create="${3}"
dry_mode="${4:-1}"  # Default to dry_mode=true (1) if not provided

if [ "${dry_mode}" -ne 1 ] && [ "${dry_mode}" -ne 0 ]; then
    echo "ERROR: dry_mode value [${dry_mode}] is not 0|1. Can not continue."
    exit 1
fi


current_test_name=$(basename "$0" .sh)
dropbox_uuid=$(basename "${dropbox_uuid_path}")

if [ "${dry_mode}" -eq 1 ]; then
    is_skipped="# SKIP DRY-RUN"
fi

echo "# Subtest: ${current_test_name}"

check_folder "${dropbox_uuid_path}" "source folder"
check_folder "${target_folder}" "target folder"

run_rsync_and_flag "${dropbox_uuid_path}" "${target_folder}" "${dropbox_uuid}" "${flag_file_to_create}"

echo -e "    1..${nb_tests}"
if [ "${flag_ok}" -eq 1 ]; then
    echo -e "ok - ${current_test_name} ${is_skipped}"
else
    echo -e "not ok - ${current_test_name} ${is_skipped}"
fi

