function bits2str(bits,        data, mask)
{
    if (bits == 0)
        return "0"

    mask = 1
    for (; bits != 0; bits = rshift(bits, 1))
        data = (and(bits, mask) ? "1" : "0") data

    while ((length(data) % 8) != 0)
        data = "0" data

    return data
}

function array_push(arr, value,    i) {
    i = length(arr) + 1
    arr[i] = value
}

function concat_str(array, str) {
    if ("DATA_FOLDER_URL" in array && array["DATA_FOLDER_URL"] != "") {
        current = array["DATA_FOLDER_URL"];  
        array["DATA_FOLDER_URL"] = current "," str;
    } else {
        array["DATA_FOLDER_URL"] = str;
    }
}

BEGIN{

    if(no_header != 1)
        no_header = 0

    if(regex_file == ""){
        error_flag = error_flag "ERROR: regex_file variable is mandatory."
    }

    if (error_flag != "") exit 1
    
    FS="/"
    OFS="\t"
    nb_line=1
    
    while ((getline line < regex_file) > 0) {
        if(fields[1] ~ /^#/)
            continu
        split(line, fields, "\t")
        regexes_data[nb_line]["regex"] = fields[1]
        regexes_data[nb_line]["std"] = fields[2]
        regexes_data[nb_line]["type"] = fields[3]
        regexes_data[nb_line]["action"] = fields[4]
        regexes_data[nb_line]["message"] = fields[5]
        nb_line++
    } 
    close(regex_file)
    if (length(regexes_data) <= 1) {
        print "Error: Unable to open or read from '" regex_file "'. Make sure the file exists and is readable."
        exit 1
    }
}

ARGIND == 1{
    ## PROVIDER_flags_list
    split($NF, arr, "\t")
    dropbox_uuid=arr[1]
    custom_action=arr[2]
    custom_message=arr[3]

    match(dropbox_uuid,/(.*)_([0-9a-fA-F-]+)_([0-9]{8})\.(.*)/,arr)
    qbbid=arr[1]
    uuid=arr[2]
    date=arr[3]
    flag=arr[4]
    
    if (custom_action != "")
        data_tests[qbbid][qbbid"_"uuid"_"date]["PROVIDER_CUSTOM_ACTION"]=custom_action
    if (custom_message != "")
        data_tests[qbbid][qbbid"_"uuid"_"date]["PROVIDER_CUSTOM_MESSAGE"]=custom_message

    tmp_bit=0
    if(qbbid in data_tests && qbbid"_"uuid"_"date in data_tests[qbbid] && "PROVIDER_FLAGS" in data_tests[qbbid][qbbid"_"uuid"_"date]){
        tmp_bit=data_tests[qbbid][qbbid"_"uuid"_"date]["PROVIDER_FLAGS"]
    }
    switch (flag){
        case /PASS/:
            data_tests[qbbid][qbbid"_"uuid"_"date]["PROVIDER_FLAGS"]=or(tmp_bit,lshift(1,2))
            break
        case /LEGACY/:
            data_tests[qbbid][qbbid"_"uuid"_"date]["PROVIDER_FLAGS"]=or(tmp_bit,lshift(1,1))
            break
        case /FORCED/:
            data_tests[qbbid][qbbid"_"uuid"_"date]["PROVIDER_FLAGS"]=or(tmp_bit,1)
            break
    }    

    # print "PROVIDER",qbbid,qbbid"_"uuid"_"date,bits2str(tmp_bit)
}

ARGIND == 2{
    ## MY_ORG_flags_list
    match($NF,/(.*)_([0-9a-fA-F-]+)_([0-9]{8})\.(.*)/,arr)
    qbbid=arr[1]
    uuid=arr[2]
    date=arr[3]
    flag=arr[4]
    
    tmp_bit=0
    if(qbbid in data_tests && qbbid"_"uuid"_"date in data_tests[qbbid] && "MY_ORG_FLAGS" in data_tests[qbbid][qbbid"_"uuid"_"date]){
        tmp_bit=data_tests[qbbid][qbbid"_"uuid"_"date]["MY_ORG_FLAGS"]
    }

    switch (flag){
        case /DELIVERED/:
            data_tests[qbbid][qbbid"_"uuid"_"date]["MY_ORG_FLAGS"] = or(tmp_bit,lshift(1,2))
            break
        case /TO_REVIEW/:
            data_tests[qbbid][qbbid"_"uuid"_"date]["MY_ORG_FLAGS"] = or(tmp_bit,lshift(1,1))
            break
        case /REJECTED/:
            data_tests[qbbid][qbbid"_"uuid"_"date]["MY_ORG_FLAGS"] = or(tmp_bit,1)
            break
    }

    # print "MY_ORG_FLAG",qbbid,qbbid"_"uuid"_"date,bits2str(tmp_bit)
}

ARGIND == 3{
    ## dropbox_uuid_path_list
    match($NF,/(.*)_([0-9a-fA-F-]+)_([0-9]{8})/,arr)
    qbbid=arr[1]
    uuid=arr[2]
    date=arr[3]

    tmp_bit=0
    if(qbbid in data_tests && qbbid"_"uuid"_"date in data_tests[qbbid] && "DATA_FOLDER" in data_tests[qbbid][qbbid"_"uuid"_"date]){
        tmp_bit=data_tests[qbbid][qbbid"_"uuid"_"date]["DATA_FOLDER"]
    }

    data_tests[qbbid][qbbid"_"uuid"_"date]["DATA_FOLDER"]=or(tmp_bit,lshift(1,2))
    concat_str(data_tests[qbbid][qbbid"_"uuid"_"date],$0)

    # print "DATA_FOLDER",qbbid,qbbid"_"uuid"_"date,bits2str(tmp_bit)
}

ARGIND == 4{
    ## delivered_uuid_path_list
    match($NF,/(.*)_([0-9a-fA-F-]+)_([0-9]{8})/,arr)
    qbbid=arr[1]
    uuid=arr[2]
    date=arr[3]
    
    tmp_bit=0
    if(qbbid in data_tests && qbbid"_"uuid"_"date in data_tests[qbbid] && "DATA_FOLDER" in data_tests[qbbid][qbbid"_"uuid"_"date]){
        tmp_bit=data_tests[qbbid][qbbid"_"uuid"_"date]["DATA_FOLDER"]
    }

    data_tests[qbbid][qbbid"_"uuid"_"date]["DATA_FOLDER"]=or(tmp_bit,lshift(1,1))
    concat_str(data_tests[qbbid][qbbid"_"uuid"_"date],$NF)

    # print "DATA_FOLDER",qbbid,qbbid"_"uuid"_"date,bits2str(tmp_bit)
}

ARGIND == 5{
    ## rejected_uuid_path_list
    match($NF,/(.*)_([0-9a-fA-F-]+)_([0-9]{8})/,arr)
    qbbid=arr[1]    
    uuid=arr[2]
    date=arr[3]
   
    tmp_bit=0
    if(qbbid in data_tests && qbbid"_"uuid"_"date in data_tests[qbbid] && "DATA_FOLDER" in data_tests[qbbid][qbbid"_"uuid"_"date]){
        tmp_bit=data_tests[qbbid][qbbid"_"uuid"_"date]["DATA_FOLDER"]
    }

    data_tests[qbbid][qbbid"_"uuid"_"date]["DATA_FOLDER"]=or(tmp_bit,1)
    concat_str(data_tests[qbbid][qbbid"_"uuid"_"date],$NF)

    # print "DATA_FOLDER",qbbid,qbbid"_"uuid"_"date,bits2str(tmp_bit)
}

END{
    if(error_flag != "" ){
        printf "%s", error_flag > "/dev/stderr"
        exit 1
    }
    if(no_header == 0)
        print "TIMESTAMP","ACTION","QBB_ID","DROPBOX_UUID","CASE_NUMBER","MESSAGE","CUSTOM MESSAGE","DROPBOX_DATA_FOLDER"

    for (qbbid in data_tests){
        for (dropbox_uuid in data_tests[qbbid]){
            data_folder_url=data_tests[qbbid][dropbox_uuid]["DATA_FOLDER_URL"]
            data_folder=data_tests[qbbid][dropbox_uuid]["DATA_FOLDER"]+0
            PROVIDER_flags=data_tests[qbbid][dropbox_uuid]["PROVIDER_FLAGS"]+0
            MY_ORG_flags=data_tests[qbbid][dropbox_uuid]["MY_ORG_FLAGS"]+0
            decimal_value=data_folder""PROVIDER_flags""MY_ORG_flags
            if("PROVIDER_CUSTOM_MESSAGE" in data_tests[qbbid][dropbox_uuid])
                PROVIDER_custom_message=data_tests[qbbid][dropbox_uuid]["PROVIDER_CUSTOM_MESSAGE"]
            else
                PROVIDER_custom_message=""

            if("PROVIDER_CUSTOM_ACTION" in data_tests[qbbid][dropbox_uuid]){
                print timestamp,data_tests[qbbid][dropbox_uuid]["PROVIDER_CUSTOM_ACTION"],qbbid,dropbox_uuid,decimal_value,PROVIDER_custom_message,data_folder_url> "/dev/stderr"
            }else{
                ok=0
                if(PROVIDER_flags != 0){ # only cases with PROVIDER_FLAG
                    for (i = 1; i <= length(regexes_data); i++) {
                        if (match(decimal_value, regexes_data[i]["regex"])) {
                            print timestamp,regexes_data[i]["action"],qbbid,dropbox_uuid,decimal_value,regexes_data[i]["message"],PROVIDER_custom_message,data_folder_url > "/dev/"regexes_data[i]["std"]
                            ok=1
                            break
                        }
                    }
                    if (!ok)
                        print timestamp,"ERROR:UNSUPORTED_CASE",qbbid,dropbox_uuid,decimal_value,"No regex for this case. Please, contact the developper",data_folder_url> "/dev/stderr"
                }
            }

        }
    }
}