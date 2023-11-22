#!/bin/bash

#######################################################################################################
## this script splits contigs in one file to many files. Each new file has specified number of 
## contigs --- last one may have different number
##
## usage: sh func_split_contig.sh -i input_contig_file.txt -n number_of_contigs
##        e.g., 50 contigs per file, then number_of_contigs=50
##
## application example: VHM/MARVEL take long time to run all contigs at one time, it will save tons of 
##                 time to run each splited contig file individually, then you can combine the outputs.
#######################################################################################################


## help message
usage() {
echo -e "
This script splits contigs in one file to many files. Each new file has specified number of contigs

Required arguments:
-i      input contig file (fasta format)

-n      number of contigs in each new splited file (default: 50). e.g., there are 172 contigs in one file,
        it will then generate 4 files with 50, 50, 50, and 22 contigs, respectively.

-o      output folder name (default: "splited_contigs" in the same folder of input contig file)

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
number_new=50
output_folder=splited_contigs
while getopts "i:n:o:" opt
do
  case $opt in
    i)
        input_contig_file=$OPTARG;;

    n) 
        number_new=$OPTARG;;

    o)
        output_folder=$OPTARG;;

    \?)
        echo "invalid argument"
        exit 1;;
  esac
done

## message
echo -e "    Split input file: ${number_new} contigs in each new file.\n"

## path of base working directory
path_input=$(readlink -f $input_contig_file)
workDir=${path_input%/*}
cd $workDir

## input contig file (full path)
input_cont=${path_input}

## folder & file name (here, workDir = input_cont_folder)
input_cont_folder=${input_cont%/*}
input_cont_file=${input_cont##*/}
input_cont_name=${input_cont_file%.*}

## make contig file with each contig as one line
cd $input_cont_folder
cat $input_cont_file | awk '/^>/ {printf("\n%s\n",$0);next; } { printf("%s",$0);}  END {printf("\n");}' | sed '/^$/d; /--/d' > ${input_cont_name}_oneline.fna
input_cont=${input_cont_folder}/${input_cont_name}_oneline.fna

## in case some spacers will be removed after one line transfer
# input_cont=${path_input}

## decide split number according to "-n" argument
cont_number=$(grep -c "^>" ${input_cont})
split_number=$((cont_number/number_new))
cont_number_tem=$((split_number*number_new))
cont_number_tail=$((cont_number-cont_number_tem))

## decide if need to split according to the $cont_number and $number_new
# make a folder to collected contig files that do not need to split (if there is any)
if [ -d "${input_cont_folder}/unsplited_contigs" ]; then
  echo -e "\c"
else
  mkdir ${input_cont_folder}/unsplited_contigs
fi
# decide if need to split
if [ $cont_number -le $number_new ]; then
  echo -e "    No need to split for this file: ${input_cont_name}"
  mv ${input_cont_folder}/${input_cont_name}_oneline.fna ${input_cont_folder}/unsplited_contigs/${input_cont_name}.fasta
  exit 1
else
  echo -e "    Split to ${split_number} (+1) files for this file: ${input_cont_name}"
fi

## output folder
if [[ "${output_folder:0:1}" == / || "${output_folder:0:2}" == ~[/a-z] ]]
then
  if [ -d "$output_folder" ]
  then
    cd $output_folder
  else
    mkdir $output_folder
    cd $output_folder
  fi

else
  output_folder_short=${output_folder##*/}
  if [ -d "${workDir}/${output_folder_short}" ]
  then
    cd ${workDir}/${output_folder_short}
    # rm -r ${workDir}/${output_folder_short}/* # clean folder
  else 
    mkdir ${workDir}/${output_folder_short}
    cd ${workDir}/${output_folder_short}
  fi

fi


## split contigs
for split_order in $(seq 1 ${split_number})
do
	line_number_bottom=$(((split_order-1)*number_new*2+1))
	line_number_up=$((split_order*number_new*2))
	 
	sed -n "${line_number_bottom},${line_number_up}p" $input_cont > ${input_cont_name}_${split_order}.fna
done

# tail contigs
if [ $cont_number_tail -eq 0 ]
then
	split_number_final=$split_number
else
	split_number_final=$((split_number+1))
	line_number_bottom=$(((split_number*number_new*2)+1))
	line_number_up=$(((split_number*number_new*2)+cont_number_tail*2))
	sed -n "${line_number_bottom},${line_number_up}p" $input_cont > ${input_cont_name}_${split_number_final}.fna
fi

## clean folders
cd ${input_cont_folder}
rm ${input_cont_folder}/${input_cont_name}_oneline.fna

