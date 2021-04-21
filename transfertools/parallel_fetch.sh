#!/bin/bash
# This code is intended to facillitate downloading bulk UKB data.
# Need: 1) fetch utility, 2) bulkfile 3) keyfile 4) array idx 5) num jobs

helpstr="$(basename $0) [-h] [-n numjobs] [-f field_id] [-b bulkfile] [-p blocklist] [-s] fetch_utility keyfile

where:
  -h                            Show this message.
  -n, --numjobs NUM		Number of parallel downloads. Default 10.
  -f, --field FIELD_ID		Field ID to download. If unspecified, download all available data from bulkfile.
  -b, --bulkfile BULK		File obtained from ukbconv [...] bulk. Required if fetch_utility is ukbfetch
  -p, --blocklist BLOCK		Block list info, 'pvcf_blocks.txt'. Required for Data-Field 23156.
  -s, --skip			If set, skip file if already present at output. Default 0.
  fetch_utility			Path to either ukbfetch (bulk imaging) or gfetch (bulk genetics)
  keyfile			Path to authentication key provided by the UKB.

Example use:
bash $(basename $0) -f 20250_2_0 -b dataset.bulk -s ukbfetch k123r567.key
"

# Parse inputs
skipflag=0
njob=10
pos_args=()
while (( "$#" )); do
        case "$1" in
		-h|--help)
		  echo "${helpstr}"
		  exit 0
		  ;;
		-n|--numjobs)
		  # number of jobs downloading the data (used to determine how much each should download)
		  njob="${2}"
		  shift 2
		  ;;
		-f|--field)
		  # field id
		  field="${2}"
		  shift 2
		  ;;
		-b|--bulkfile)
		  # bulk file; used with ukbfetch instead of gfetch (same structure!)
		  bulkfile="${2}"
		  shift 2
		  ;;
		-p|--blocklist)
		  # pvcf_blocks.txt
		  blocklist="${2}"
		  shift 2
		  ;;
		-s|--skip)
		  # if 1: skip if file is already present; default 1
		  skipflag=1
		  shift 1
		  ;;
		-*|--*)
                  >&2 echo "Invalid flag ${2}"
                  exit 1
                  ;;
		*)
		  pos_args+=("${1}")
		  shift 1
		  ;;
        esac
done

fetch=`readlink -f ${pos_args[0]}`
keyfile=${pos_args[1]}


echo "Checking input values..."
# Check that all necessary variables are defined
if [ -z "${fetch}" ]; then
	>&2 echo "Fetch utility undefined"
	exit 1
fi
if [ -z "${keyfile}" ]; then
	>&2 echo "Keyfile undefined."
	exit 1
fi

# Define download unit
dload () {
local chrom
chrom="${1}"
${fetch} ${field} -c${chrom} -a${keyfile}
${fetch} ${field} -c${chrom} -m -a${keyfile}
}

# Define download unit (with blocks!)
dload_block () {
local chrom
local block
chrom="${1}"
block="${2}"
${fetch} ${field} -c${chrom} -b${block} -a${keyfile}
}

dload_bulk () {
local startind
local maxfiles
startind="${1}"
maxfiles=1000
${fetch} -b${bulkfile} -a${keyfile} -s${startind} -m${maxfiles}
}

chromlist=(`seq 1 22`)
chromlist+=(X Y XY MT)

job_ind=0
echo "Downloading!"
if [ ! -z ${blocklist} ]; then
	# Go through each line in blocklist to get chrom-block pair
	# blocklist specified; gfetch & blockfile parse
	echo "Parsing blockfile ${blockfile}!"
	while read -r binfo; do
		barr=(${binfo})
		chrom=${barr[1]}
		block=${barr[2]}
		if [ ${skip} -eq 1 ]; then
			if [ -f "ukb${field}_c${chrom}_b${block}_v1.vcf.gz" ]; then
				echo "Found file; skipping: ukb${field}_c${chrom}_b${block}_v1.vcf.gz"
				continue
			fi
		fi
		dload_block ${chrom} ${block} &
		job_ind=$((job_ind+1))
		if [ ${job_ind} -ge ${njob} ]; then
			wait
			job_ind=0
		fi
	done < ${blocklist}
elif [ ! -z ${bulkfile} ]; then
	# bulkfile is specified; use ukbfetch
	echo "Parsing bulkfile ${bulkfile}!"
	maxfiles=1000
	numlines=`cat ${bulkfile} | wc -l`  # number of specified files
	numsub=$((1+numlines/maxfiles))
	job_ind=0
	for i in `seq 0 ${numsub}`; do
		startind=$((maxfiles*i))
		echo "Startind: ${startind}"
		dload_bulk ${startind} &
		job_ind=$((job_ind+1))
		if [ ${job_ind} -ge ${njob} ]; then
			wait
			job_ind=0
		fi
	done
elif [ -z ${blocklist} ]; then
	echo "Downloading genetics data!"
	for chrom in ${chromlist[@]}; do
		dload ${chrom} &
		job_ind=$((job_ind+1))
		if [ ${job_ind} -ge ${njob} ]; then
			wait
			job_ind=0
		fi
	done
fi

