#!/bin/bash


## working directory
workDir=~/working_folder/
cd $workDir

input_file=${workDir}/Accession-number_sample-name.txt

## tools
export PATH=/users/PAS1117/osu7810/software/sratoolkit.2.10.5-ubuntu64/bin:$PATH

## run download in parallel
func_SRA_download () {
  local acc=$1
  local samname=$2
  fastq-dump --gzip --skip-technical --readids --read-filter pass --dumpbase --split-e --clip $acc
  mv ${acc}_pass_1.fastq.gz ${samname}_pass_1.fastq.gz
  mv ${acc}_pass_2.fastq.gz ${samname}_pass_2.fastq.gz

  # merge to interleaved reads
  sh /bbmap_38.43/reformat.sh in1=${samname}_pass_1.fastq.gz in2=${samname}_pass_2.fastq.gz out=${workDir}/${samname}_interleaved_reads.fastq.gz

  # clean tem file
  rm /users/PAS1117/osu7810/1_Test_tools/17_SRA/sra/${acc}.sra
}

## get sample number
sample_num=$(cat $input_file | sed "1d" | wc -l)
for sample_number_real in $(seq $sample_num)
do
  line_num=$((sample_number_real + 1))
  line=$(cat $input_file | sed -n "$line_num"p)

  acc_tem=$(echo $line | cut -f1 -d " ")
  samname_tem=$(echo $line | cut -f2 -d " ")
  echo "${acc_tem} ${samname_tem}"

  func_SRA_download "$acc_tem" "$samname_tem" & 

done
wait


