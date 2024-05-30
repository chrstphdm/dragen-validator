#!/bin/bash

############################################################
# DESCRIPTION
## Check dropbox_uuid existence and dragen files existence/integrity
## Print TAP formatted results.
#
# INPUT
## $1: dropbox_uuid_path
## $2: sample_id
## $3: skip_optionnals ; 1=true | (0 or empty)=false
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
            echo -e "    ok ${nb_tests} - $2 folder is readable"
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
        echo "    not ok ${nb_tests} - file $(basename "$1") is missing ${2}"
        if [[ "${2}" == "" ]]; then ## no skip_optionnals_str for this test
            flag_ok=0
        fi
    else
        echo "    ok ${nb_tests} - file $(basename "$1") exists ${2}"
        (( nb_tests++ )) || true
        if [ -r "$1" ] ; then
            echo -e "    ok ${nb_tests} - file $(basename "$1") is readable ${2}"
        else
            echo -e "    not ok ${nb_tests} - file $(basename "$1") is not readable ${2}"
            if [[ "${2}" == "" ]]; then ## no skip_optionnals_str for this test
                flag_ok=0
            fi
        fi
    fi
}

check_pattern_file_existence() {
    (( nb_tests++ )) || true
    directory="$1"
    matching_files=$(find "${directory}/" -maxdepth 1 -type f -name "$2")
    if [[ -z $matching_files ]]; then
        echo "    not ok ${nb_tests} - NO file with pattern [$2] exists in $(basename "$1")"
        flag_ok=0
    else
        echo "    ok ${nb_tests} - at least one file with pattern [$2] exists in $(basename "$1")"
    fi
}

check_file_content() {
    (( nb_tests++ )) || true
    if [[ ! -s "$1" ]]; then
        echo "    not ok ${nb_tests} - file $(basename "$1") is empty ${2}"
        if [[ "${2}" == "" ]]; then ## no skip_optionnals_str for this test
            flag_ok=0
        fi
    else
        echo "    ok ${nb_tests} - file $(basename "$1") is not empty ${2}"
    fi
}

check_meta_in_cram() {
    # this is not used for checking, this is only to extract metadata about instrument, run_id and flowcell
    # 
    (( nb_tests++ )) || true
    meta_data=$(samtools view -T /mnt/data_jrnas1/ref_data/Hsapiens/hg38/seq/hg38.fa  "$1" | head -n 1  | gawk -F':' 'BEGIN{OFS=","}{print $1,$2,$3;exit 1}' -)
    if [ $? -eq 1 ]; then
        echo "    ok ${nb_tests} - [instrument_id,run_id,flowcell_id] fields of $(basename "$1") are correct [${meta_data}]"
    else
        echo "    not ok ${nb_tests} - [instrument_id,run_id,flowcell_id] fields of $(basename "$1") are not correct"
        flag_ok=0
    fi
    
}

check_sample_id_in_cram() {
    (( nb_tests++ )) || true
    if [[ $(samtools view -H "$1" | grep -c -P "^@RG.*SM:$2") -eq 0 ]]; then
        echo "    not ok ${nb_tests} - 'SM:$2' field of $(basename "$1") is not correct"
        flag_ok=0
    else
        echo "    ok ${nb_tests} - 'SM:$2' field of $(basename "$1") is correct"
    fi
}

check_md5sum() {
    (( nb_tests++ )) || true
    md5_file="${1}"
    if [[ ! -e "${md5_file}" ]]; then
        echo "    not ok ${nb_tests} - md5sum file $(basename "${md5_file}") does not exists ${2}"
    else
        normal_file=$(basename "${1}" .md5sum)
        md5_stdout=$(echo "$(cat "${md5_file}") ${dropbox_uuid_path}/${normal_file}" | md5sum -c - 2>/dev/null)
        # shellcheck disable=SC2181
        if [[ $? -ne 0 ]]; then
            if [[ "${2}" == "" ]]; then ## no skip_optionnals_str for this test
                flag_ok=0
            fi
        fi
        echo "${md5_stdout}" | awk -v nb="${nb_tests}" -v skip_optionnals_str="${2}" 'BEGIN{FS="(: |/)"}$NF ~ /OK|FAILED/{
            if($NF == "OK"){
                printf "    ok %i - md5sum verification for %s is correct %s\n", nb, $(NF-1), skip_optionnals_str
            } else {
                printf "    not ok %i - md5sum verification for %s is not correct %s\n", nb, $(NF-1), skip_optionnals_str
            }
        }' -
    fi
}

# if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    ## Main script
    current_test_name=$(basename "$0" .sh)
    dropbox_uuid_path="${1}"
    sample_id="${2}"
    skip_optionnals="${3}"

    flag_ok=1
    nb_tests=0
    skip_optionnals_str=""
    if [[ "${skip_optionnals}" -eq 1 ]]; then
        skip_optionnals_str="# SKIP"
    fi

    echo "# Subtest: ${current_test_name}"

    check_folder "$dropbox_uuid_path" "dropbox_uuid"

    mandatory_files=(\
    # shellcheck disable=SC1143
    "cram" "cram.crai" "cram.md5sum" \
    "hard-filtered.gvcf.gz" "hard-filtered.gvcf.gz.tbi" "hard-filtered.gvcf.gz.md5sum" \
    "hard-filtered.vcf.gz" "hard-filtered.vcf.gz.tbi" "hard-filtered.vcf.gz.md5sum" \
    "targeted.vcf.gz" "targeted.vcf.gz.tbi" "targeted.vcf.gz.md5sum" \
    "mapping_metrics.csv" "wgs_overall_mean_cov.csv" "wgs_coverage_metrics.csv" "ploidy_estimation_metrics.csv")
    for i in "${!mandatory_files[@]}"; do
        file_type="${mandatory_files[$i]}"
        file_path="${dropbox_uuid_path}/${sample_id}.${mandatory_files[$i]}"

        check_file_existence "$file_path"
        check_file_content "$file_path"

        if [[ "$file_type" == *".md5sum" ]]; then
            check_md5sum "$file_path"
        fi
    done

    optional_files=(
    "cnv.vcf.gz" "cnv.vcf.gz.tbi" "cnv.vcf.gz.md5sum" \
    "cnv_sv.vcf.gz" "cnv_sv.vcf.gz.tbi" "cnv_sv.vcf.gz.md5sum" \
    "ploidy.vcf.gz" "ploidy.vcf.gz.tbi" "ploidy.vcf.gz.md5sum")
    for i in "${!optional_files[@]}"; do
        file_type="${optional_files[$i]}"
        file_path="${dropbox_uuid_path}/${sample_id}.${optional_files[$i]}"

        check_file_existence "$file_path" "${skip_optionnals_str}"
        check_file_content "$file_path" "${skip_optionnals_str}"

        if [[ "$file_type" == *".md5sum" ]]; then
            check_md5sum "$file_path" "${skip_optionnals_str}"
        fi
    done

    check_sample_id_in_cram "${dropbox_uuid_path}/${sample_id}.cram" "$sample_id"
    check_meta_in_cram "${dropbox_uuid_path}/${sample_id}.cram"
    check_pattern_file_existence "${dropbox_uuid_path}" "*_usage.txt"
    check_pattern_file_existence "${dropbox_uuid_path}" "*_dragen_output.log"
    check_pattern_file_existence "${dropbox_uuid_path}" "dragen_run_*.log"

    echo "    1..${nb_tests}"
    if [[ "$flag_ok" -eq 1 ]]; then
        echo "ok - ${current_test_name}"
    else
        echo "not ok - ${current_test_name}"
    fi
# fi