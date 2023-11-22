#!/bin/bash

#####################################################################
# length cut for the fasta contigs -- get contigs >= length
# usage: bash func_length-cut.sh -i contig_file.fasta -l <length>
#
# email: zhongzhipingemail@gmail.com
#####################################################################

usage() {
echo -e "
length cut for the fasta contigs -- get contigs >= length
usage: bash func_length-cut.sh -i contig_file.fasta -l <length>
e.g., bash func_length-cut.sh -i contigs.fasta -l 5000 (get contigs >=5kb)

Parameters:
-i      input fasta file; works for both nucleoties and amino acids (required)
-l      length (bp), get contigs >= this length (optional; default: 1bp)
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

## arguments and variables
length=1
while getopts "i:l:" opt
do
  case $opt in
    i)
        input_cont=$OPTARG;;
    l)
        length=$OPTARG;;
    \?)
        echo "invalid argument"
        exit 1;;
  esac
done



## path of base working directory
path_input=$(readlink -f $input_cont)
workDir=${path_input%/*}
cd $workDir

## names
name_input_cont_tem=${path_input##*/}
name_input_cont=${name_input_cont_tem%.*}
name_extention=${name_input_cont_tem##*.}

## names - length
if [ $length -lt 1000 ]
then
  name2=$(echo "scale=1; $length/1000"|bc)
  name2="0"$name2   
else 
  name2=$(echo "scale=1; $length/1000"|bc)
fi

## run length cut
cat $path_input | awk '/^>/ {printf("\n%s\n",$0);next; } { printf("%s",$0);}  END {printf("\n");}' | sed '/^$/d; /^--$/d' | awk '{y= i++ % 2 ; L[y]=$0; if(y==1 && length(L[1])>='$length') {printf("%s\n%s\n",L[0],L[1]);}}' > ${name_input_cont}_${name2}kb.${name_extention}


echo -e "  Input file: ${input_cont}; length cut >= ${length}bp; output: ${name_input_cont}_${name2}kb.${name_extention}\n"

