#!/bin/bash


helpstr="$(basename "$0") [-h] subject_list

where:
  -h                            Show this message.
  subject_dirs                  Text file containing the subject directories to check.
"

posargs=()
while (( "$#" )); do
  case "$1" in
    -h|--help)
      echo ${helpstr}
      exit 0
      ;;
    -*|--*)
      >&2 echo "Unrecognized option: ${1}"
      exit 1
      ;;
    *)
      posargs+=("$1")
      shift 1
      ;;
  esac
done

subject_list=${posargs[0]}

for sub in `cat ${subject_list}`; do
  if [ -d ${sub} ]; then
    echo "1"
    exit 0
  fi
done

echo "0"
exit 0