
# Quick and dirty manual

## generate_delivery_list

generate_delivery_list - an application to print validated data **in** stdout and incorrect data in stderr

### SYNOPSIS

**[ENV VARIABLES] generate_delivery_list [stdout redirections] [stderr redirections]**

### Some ENV VARIABLES

Only optionals because set by default.

`DATA_ROOT_PATH`: Folder where the application will scan for FLAGS and DATA. Default: **/mnt/ngsdata/WGS/**

`DRAGEN_VALIDATOR_DIR`: dragen-validator installation dir. Used to find the generate_delivery_list.awk script. Default: **folder of the generate_delivery_script**

`REGEX_FILE`: file used to describe cases and corresponding messages. Default: **"${DRAGEN_VALIDATOR_DIR}/assets/regex.tsv"**

`DEBUG`: will keep temporary files in `/tmp/` for debug and will print paths on stderr. Will also add `DROPBOX_DATA_FOLDER` in the output lists.

### Some exemples

By correctly redirecting stdout and stderr, you can easily save or view the results.

1. Save stdout in `delivery_list.tsv` and ignore the stderr :

```bash
generate_delivery_list > delivery_list.tsv 2>/dev/null
```

2. Save stdout in `delivery_list.tsv` and stderr in ` error_list.tsv` :

```bash
generate_delivery_list > delivery_list.tsv 2> error_list.tsv
```

3. 
```bash
generate_delivery_list > delivery_list.tsv 2>/dev/null
```
We can easly format 

By using `pspg`, we can access to a TSV viewer, sort data and search. Start by loading the module with `module load pspg/5.5.3`. Details about the `pspg` [commands here](https://github.com/okbob/pspg?tab=readme-ov-file#backslash-commands).

1. View only the delivery list :

```bash
generate_delivery_list 2>/dev/null | pspg --tsv
```

2. View only the list of errors :

```bash
generate_delivery_list 2>&1 >/dev/null | pspg --tsv
```

## dragen-validator 

dragen-validator - a fast pipeline to check, copy and flag DATA, following MY_ORG business rules.

### Some ENV VARIABLES

`DATA_ROOT_PATH`: Folder where the application will scan for FLAGS and DATA. Default: **/mnt/ngsdata/WGS/**

`RESULTS_ROOT_PATH`: Folder where the application will save each instance of results. Default: **TODO**

### Options

`--delivery_list TSV_DELIVERY_LIST`: TSV file generated from **generate_reports** stdout. **MANDATORY**

`--dry [true|false]`: perform a trial run with no changes made (default **true**)

`-resume`: resume the latest run of dragen-validator. Useful for recovering from errors.


### Some exemples

```bash
dragen-validator --delivery_list delivery_list.tsv
```