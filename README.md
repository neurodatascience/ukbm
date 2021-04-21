UKB Manager
---
## About
`ukbm` is a collection of code for facillitating data management of the [UK Biobank](https://www.ukbiobank.ac.uk/) [bulk data](https://biobank.ctsu.ox.ac.uk/crystal/crystal/docs/ukbfetch_instruct.html). The code allows users to manage downloads by splitting by modality, limiting downloads to new data, and parallelize fetching. Data structure conversion to [BIDS](https://bids-specification.readthedocs.io/en/stable/) is supported for NIFTI data (e.g. [T1 images](https://biobank.ndph.ox.ac.uk/showcase/field.cgi?id=20252)). High-level SLURM submission scripts are included for deploying extraction and conversion scripts on computing clusters. Finally, SquashFS-related utilities are provided to help converting the data into SquashFS and handling common tasks (e.g. subject removal, patching). `ukbm` relies on the UKB's [download utilities](https://biobank.ctsu.ox.ac.uk/showcase/download.cgi) for fetching the data.

## Data Fetching  
### Fetching from the UKB
Data fetching is done via `transfertools/parallel_fetch.sh`, which in turn relies on `ukbfetch` or `gfetch`. `parallel_fetch` splits a bulk download evenly into parallel processes. Assuming that the transfer speed is not saturated, the parallel download can speed up transfer by up to a factor of 10x. The code is called via:
````bash
bash parallel_fetch.sh [-n numjobs] [-s] [-f field_id] [-b bulkfile] [-p blocklist] fetch_utility keyfile
````
where:
|Argument name/flag	| Required? : Default 	| Description|
|-----------------------|---------------------	|------------|
|-n, --numjobs NUM	| No : 10		|Number of parallel processes to start.		|
|-s, --skip		| No : 0		|If set, check whether files are already present at output.|
|-f, --field FIELD	| Maybe : None.		|Required for genetics data; optional for bulk data. Limit fetching to a particular datafield.|
|-b, --bulkfile BULK	| Maybe : -		|Required if downloading via a bulkfile; not needed if downloading genetics data.|
|-p, --blocklist BLOCK	| Maybe : -		|Required if downlaoding genetics via by blocks; not needed otherwise. E.g. [pvcf_blocks.txt](https://biobank.ndph.ox.ac.uk/showcase/refer.cgi?id=837)|
|fetch_utility		| Yes : -		|Path to the UKB's fetch utility to use. Should be `ukbfetch` for bulk imaging data, `gfetch` for genetics|
|keyfile		| Yes : -		|Path the the keyfile supplied by the UKB once a basket is made available.|

#### Example uses
````bash
bash parallel_fetch.sh -n 6 -f 20252_2_0 -b dataset.bulk -s ukbfetch k12345r000000.key  # Bulk data; downloads only 20252_2_0
bash parallel_fetch.sh -f 23156 -p pvcf_blocks.txt gfetch k12345r000000.key  # Exome pVCF file blocks
bash parallel_fetch.sh -f 22418 gfetch k12345r000000.key  # Genotype calls
````

### Resuming
For resuming partially-completed downloads and avoiding previously-fetched data, we can use `transfertools/reduce_bulkfile.py` to reduce the initial bulkfile to only the missing data:
````bash
python reduce_bulkfile.py [-v] [-f FIELD] [-d DATA] bulkfile output
````
where:
|Argument name/flag	| Required? : Default 	| Description|
|-----------------------|---------------------	|------------|
|-f, --field FIELD	| No : None		|Limit reduction to a particular datafield.|
|-v, --verbose		| No : False		|If True, print out how much the bulkfile was reduced by.|
|-d, --datadir DIR	| No : ./		|Directory where data was stored. Defaults to current directory.|
|bulkfile		| Yes : -		|bulkfile to reduce.|
|output			| Yes : -		|Name of the output reduced bulkfile.|

#### Example
````bash
# First download:
bash parallel_fetch.sh -b dataset.bulk ukbfetch k12345r0000000.key
# [download gets interrupted]
python reduce_bulkfile.py -d [data_dir] dataset.bulk dataset_reduced.bulk
# resume using reduced bulkfile:
bash parallel_fetch.sh -b dataset_reduced.bulk ukbfetch k12345r000000.key
````

## Data Conversion
### Tabular
The tabular data is downloaded from the UKB as an encoded file. It must first be decoded, then converted into the desired format. We can do this using the wrapper functions in `convert/tabular.py`:
````bash
python tabular.py ukbfile [-a authkey] [-p ukbunpack] [-c ukbconv] [-o output] [-e encoding] [-f format_list]
````

where:
|Argument name/flag	| Required? : Default 	| Description|
|-----------------------|---------------------	|------------|
|ukbfile		| Yes : -		|File to be processed. If `-p ukbunpack` is set, the encoded file is expected. Otherwise, the decoded file is expected.|
|-a, --authkey keyfile	| Maybe : None		|Required if `-p ukbunpack` is set. Authentication key provided by the UKB.|
|-p, --ukbunpack PATH	| No : -		|Path to the `ukbunpack` utility.|
|-c, --ukbconv PATH	| No : -		|Path to the `ukbconv` utility.|
|-o, --output NAME	| No : tabular		|Output filename prefix for converted data; file extension is determined by the data format.|
|-e, --encoding PATH	| Maybe : ./encoding.ukb	|Datafield encoding (encoding.ukb) supplied by the UKB.|
|-f, --format LIST	| No : csv bulk r docs sas stata	|Output format for converted data. Valid: csv, docs, sas, stata, r, lims, bulk, txt. For multiple formats, enter the formats as a space-delimited list. Must be the last supplied argument.|

#### Example
````bash
python tabular.py dataset.enc -a k12345r000000.key -p ./ukbunpack -c ./ukbconv -o converted_output -e encoding.ukb -f bulk csv  # Do unpacking followed by conversion.
python tabular.py dataset.enc_ukb -c ./ukbconv -o converted_output -e encoding.ukb -f bulk  # Only do conversion.
python tabular.py dataset.enc -a k12345r000000.key -p ./ukbunpack  # Only do unpacking
````

### Conversion to BIDS
The bulk imaging data is supplied as NIFTI files in UKB's custom format. We can convert the raw data into BIDS using `convert/bids.py`:
````bash
python bids.py --zip_filepath ZIP [--raw_out DIR] [--source_out DIR] [--derivatives_out DIR] [--zip_filelist FILE]
````
where:
|Argument name/flag	| Required? : Default 	| Description|
|-----------------------|---------------------	|------------|
|--zip_filepath	FILE	| Maybe : -		|Zip file for data to convert to BIDS. Not required if `--zip_filelist` is defined|
|--raw_out DIR		| No : -		|Output directory for raw data. Ignored if undefined.|
|--source_out DIR	| No : -		|Output directory for source data. Ignored if undefined.|
|--derivatives_out DIR	| No : -		|Output directory for derivatives data. Ignored if undefined.|
|--zip_filelist FILE	| Maybe : -		|Text file containing a newline-delimited list of zip files to convert.|

#### Example
````bash
python bids.py --zip_filepath 123456_20252_2_0.zip --raw_out t1/raw/ --derivatives_out t1/derivs/
python bids.py --zip_filelist datalist.txt --raw_out t1/raw/
````

## SLURM Support
For clusters supporting [SLURM](https://slurm.schedmd.com/documentation.html), some batch submission scripts are provided for deploying to multiple workers. Some modification may be required to fit your specific server (e.g., removing 'module' and replacing it with the corresponding structure). The code was developed for [Compute Canada](https://docs.computecanada.ca/wiki/Compute_Canada_Documentation) clusters, which uses [Lmod](https://www.tacc.utexas.edu/research-development/tacc-projects/lmod) to manage the software environment; if your cluster uses the same tools, they should work as described here.  
  
### Conversion to BIDS  
Distributed conversion to BIDS can be done using `slurm/convert_bids.py`, which simply needs to be pointed to a directory of .zip files. Its interface is similar to `convert/bids.py`, but instead assumes that you want to convert everything in a particular directory.  
````bash
sbatch --account=ACCOUNT bids.py [--raw_out DIR] [--source_out DIR] [--derivatives_out DIR] zipdir
````
The inputs are the same as with `bids.py`. `zipdir` is simply the path to the directory containing the .zip files to be converted to BIDS. The default SBATCH settings use an array of 4 workers; you can increase the number of workers, but using more than 4 workers can cause issues when reading/writing from the same disk spaces. We recommend keeping it at 4 workers and waiting a little longer.  
  
### Creating SquashFS images
SquashFS is a read-only filesystem image that is useful for limiting the inode footprint associated with the UKB, and has the side-benefit of making data access significantly faster (see [publication](https://dl.acm.org/doi/10.1145/3311790.3401776) for more information). For a walkthrough for how to use SquashFS combined with Singularity, see the [Neurohub Wiki](https://github.com/neurohub/neurohub_documentation/wiki/5.2.Accessing-Data). We provide a SLURM batch script for creating multiple SquashFS images from a data directory, `slurm/squashdir.sh`:
````bash
sbatch --account=ACCOUNT --array=0-5 squashdir.sh [-d DEPTH] [-f FORMAT] [-n NUMIM] [--dry] directory_to_squash
````
  
where:
|Argument name/flag	| Required? : Default 	| Description|
|-----------------------|---------------------	|------------|
|-d, --depth DEPTH	| No : 0		|Depth of directory to use for splitting. E.g. /neurohub/ukbb/imaging/sub-* would require `-d 3` to split across subjects. This allows for leading directories for when the SquashFS images are overlaid.|
|-f, --format FORMAT	| No : 'neurohub_ukbb_data_${SLURM_ARRAY_TASK_ID}'	| Formatting string to use for naming output. It should change with '${SLURM_ARRAY_TASK_ID}' to prevent collisions. NOTE: input should be specified using single quotes to avoid variable expansion.|
|-n, --numim NUM	| No : ${SLURM_ARRAY_TASK_COUNT} | Only used when a subset needs to be re-squashed. Number of images that would be produced. A job that was previously-submitted with --array=0-3 would produce 4 images. If you need to re-squash image 2, you would use: sbatch --array=2 [...] squashdir.sh -n 4 [...].|
|--dry			| No : -		| If set, will not squash but will instead print the list of files that would be excluded by each worker.|
|directory_to_squash	| Yes : -		| Directory contaiing the data that needs to be squashed.|

When UKB subjects signal that they wish to be removed from the UKB, the SquashFS images need to be re-squashed. This can be done be done easily via `slurm/remove_subject.sh`, which will check specified SquashFS files against the UKB-provided subject withdrawal list and only submit SLURM jobs for images that have at least one withdrawn subject.

#### Example:
````bash
# Split the data into 6 SquashFS images with the specified output name:
sbatch --account=rpp-account-aa --array=0-5 $(basename $0) -d 3 -f 'neurohub_ukbb_rfmri_ses2_${SLURM_ARRAY_TASK_ID}_bids.squashfs' data/
````

### Modality-specific extraction from DICOMs
Some modalities (DWI, rfMRI) need their raw data to be extracted from their DICOMs due to missing information or errors in the original conversion from DICOM to NIFTI. `slurm/extract_dwi_dicom.sh` performs DICOM -> BIDS conversion for the DWI data. If the DICOMs are unavailable, you may still need to fix the DWI .bvec and .bval files. The files are tab-delimited, while BIDS expects space-delimited files; `dwi_fix_bv.sh` can do that for you.  
Similarly, some of the rfMRI files have either incorrect values in their .json files or the .json files are missing. `slurm/extract_rfmri_json.sh` extracts the .json files for each subject using `dcm2niix` and puts it in the expected BIDS-compliant path.

## Feedback / Issues
Feedback is welcome via the issues tab on GitHub.
