#!/usr/bin/env nextflow

nextflow.enable.dsl=2

include { CHECK_DELIVERY_LIST_FORMAT    } from './modules/check_delivery_list'
include { FORCED_DATA                   } from './workflows/forced_data'
include { LEGACY_DATA                   } from './workflows/legacy_data'
include { PASS_DATA                     } from './workflows/pass_data'


workflow {
    
    if (params.delivery_list == "") {
        log.error "No delivery_list specified. This is a mandatory parameter."
        exit 1
    }

    CHECK_DELIVERY_LIST_FORMAT(file(params.delivery_list, checkIfExists: true))
    .splitCsv(skip: 1, sep: "\t")
    .multiMap{
        row -> 
            // "TIMESTAMP","ACTION","QBB_ID","DROPBOX_UUID","CASE_NUMBER","MESSAGE","CUSTOM MESSAGE","DROPBOX_DATA_FOLDER"
            pass_map:   (row[1] == "TO_BE_PROCESSED:PASS")   ? [dropbox_uuid: row[3], qbb_id: row[2], dropbox_data_folder: file(row[7], checkIfExists: true), data_type: "PASS"] : []
            legacy_map: (row[1] == "TO_BE_PROCESSED:LEGACY") ? [dropbox_uuid: row[3], qbb_id: row[2], dropbox_data_folder: file(row[7], checkIfExists: true), data_type: "LEGACY"] : []
            forced_map: (row[1] == "TO_BE_PROCESSED:FORCED") ? [dropbox_uuid: row[3], qbb_id: row[2], dropbox_data_folder: file(row[7], checkIfExists: true), data_type: "FORCED"] : []
            
    }.set{delivery_data}

    PASS_DATA(delivery_data.pass_map.filter{!it.isEmpty()})
    LEGACY_DATA(delivery_data.legacy_map.filter{!it.isEmpty()})
    FORCED_DATA(delivery_data.forced_map.filter{!it.isEmpty()})

    if (params.debug){
        PASS_DATA.out.tap_reports.view()
        LEGACY_DATA.out.tap_reports.view()
        FORCED_DATA.out.tap_reports.view()

        PASS_DATA.out.tsv_reports.view()
        LEGACY_DATA.out.tsv_reports.view()
        FORCED_DATA.out.tsv_reports.view()
    }

    PASS_DATA.out.tsv_reports.concat(LEGACY_DATA.out.tsv_reports,FORCED_DATA.out.tsv_reports)
    .collectFile(name: "${params.today}.global${params.dry?".dry":""}.tsv", newLine: false, keepHeader: true, storeDir: "${params.tsv_output_folder}" )
    .subscribe {
        log.info ""
        log.info "####################################################################"
        log.info "#"
        log.info "# dropbox_uuid & ACTIONS are saved to file:"
        log.info "# ${it}"
        log.info "#"
    }

}

workflow.onComplete {
    log.info "####################################################################"
    log.info "#"
    log.info "# Pipeline completed at: $workflow.complete"
    log.info "# Execution status: ${ workflow.success ? 'OK' : 'ERROR' }"
    log.info "#"
    log.info "####################################################################"
    log.info ""
}