#!/bin/bash

###**********************************************************************
###***********************************************************************



## help message
usage() {
echo -e "
This script generate protein sequences from DNA sequences 

Required arguments:
-i      input contig file (fasta format)

Optional arguments:
-h, --help   show this help message
"
}

if [ -z "$1" ] || [[ $1 == -h ]] || [[ $1 == --help ]]; then
  usage
  exit 1
fi

## determine if the 1st argument is start with "-"
head=${1:0:1}
if [[ $head != - ]]; then
  echo "syntax error. You need an argument"
  usage
  exit 1
fi

## arguments, variables, and default values
while getopts "i:" opt
do
  case $opt in
    i)
        input_DNA_file=$OPTARG;;

    \?)
        echo "invalid argument"
        exit 1;;
  esac
done

## message
echo -e "    Generating protein sequences for: ${input_DNA_file}\n"

## path of base working directory
path_input=$(readlink -f $input_DNA_file)
workDir=${path_input%/*}
cd $workDir


## names
input_name_tem=${path_input##*/}
input_name=${input_name_tem%.*}

### run prodigal
/fs/project/PAS1117/bioinformatic_tools/Prodigal2.6.1/prodigal -i $path_input -p meta -a ${workDir}/${input_name}.faa -d ${workDir}/${input_name}_gene.fna

## get clean file
cat ${workDir}/${input_name}.faa | cut -f 1 -d " " | sed "s/\*//g" | sed "/^$/d" > ${workDir}/${input_name}_clean.faa

