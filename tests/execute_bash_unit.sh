#!/usr/bin/env bash
set -euo pipefail

clear

generate_delivery_list_binary="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/../bin/generate_delivery_list.sh"
dragen_validator_binary="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/../dragen-validator"
check_basics_binary="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/../bin/check_basics.sh"
check_copy_and_flag_binary="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/../bin/check_copy_and_flag.sh"
check_legacy_binary="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/../bin/check_legacy.sh"
check_sequencing_metrics_binary="$(dirname "$(realpath "${BASH_SOURCE[0]}")")/../bin/check_sequencing_metrics.sh"


if [[ -x "$wrapper_binary" ]]; then
  # check if bash_unit is installed
  bash_unit_binary="../bin/bash_unit"
  if [[ -x "$bash_unit_binary" ]]; then
    
     "$bash_unit_binary" 
    # if [ "$#" -gt 0 ]; then
    #   echo "USER TESTS...."
    #   TEST_SAMPLE_ID="U1a" TEST_INPUT_FILE="data/fastq_list.csv" "$bash_unit_binary" "${@}"
    # else
    #   echo "PREDEFINED TESTS...."
    #   ########### Test with CSV file
    #   TEST_SAMPLE_ID="U1a" TEST_INPUT_FILE="data/fastq_list.csv" "$bash_unit_binary" test_{all,csv}*
      
    #   ########## Test with BAM file
    #   TEST_SAMPLE_ID="U1a" TEST_INPUT_FILE="data/U1a.bam" REHEADER_SAMPLE_ID="XXXX" "$bash_unit_binary" test_{all,bam}*
    # fi

  else
    echo "This script uses https://github.com/pgrange/bash_unit for bash unit testing"
    exit 1
  fi
else
  echo "Please, install dragen-wrapper following README.md before testing."
  exit 1
fi