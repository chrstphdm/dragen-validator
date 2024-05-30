process GENERATE_TSV_REPORT{

    tag "${meta.dropbox_uuid}"

    publishDir "${params.tsv_output_folder}", 
        mode: "copy", 
        failOnError: true
    
    input:
        tuple   val(meta),
                path(tap_report),
                val(deliverable_status)

    output:
        path("${tap_report.baseName}.summary.tsv"), emit: summary_reports
        path("${tap_report.baseName}.details.tsv"), emit: details_reports

    script:
    """
   
    generate_tsv_summary_report.awk -v timestamp="${params.today}" -v data_type="${meta.data_type}" -v dropbox_uuid="${meta.dropbox_uuid}" -v qbb_id="${meta.qbb_id}" -v deliverable_status="${deliverable_status}" ${tap_report} > ${tap_report.baseName}.summary.tsv

    generate_tsv_details_report.awk -v dropbox_uuid="${meta.dropbox_uuid}" -v qbb_id="${meta.qbb_id}" ${tap_report} > ${tap_report.baseName}.details.tsv

 """
}