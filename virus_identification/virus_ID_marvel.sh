#!/bin/bash


#########################################################################################################
## this script use marvel for viral prediction (it works for contigs with all length)
##  
## 
## need to change 3 inputs: 1) input_cont, 2) outputDir=, and 3) threads_No=
#########################################################################################################

## loop
# for input_cont in *contigs_1.5kb.fasta; do name=${input_cont##*/}; sample_name=${name%.fasta*}; qsub -v input_cont=$input_cont,sample_name=$sample_name virus_ID_marvel.sh; done


## working directory  %%% need to change
workDir=~/working_folder/
cd $workDir

## input contig file (all contigs in one file)    %%%%%% need to change
# input_cont=contigs_1.5kb.fasta

## outout directory    %%%%%% need to chaange
outputDir=${workDir}/output_marvel_${sample_name}


## core number    %%%%%% need to chaange
threads_No=10


## split contigs to one contig in each file
input_cont_dir=${input_cont%/*}
mkdir $outputDir; mkdir $outputDir/split_sequences
# awk '/^>/ {OUT=substr($0,2) ".fasta"}; OUT {print >OUT}' ${input_cont}
func_split_contigs.sh -i $input_cont -n 1 -o split_sequences # a custom script to split sequences

## load tools and enter marvel base directory
module use /fs/project/PAS1117/zhiping/software/1_modules/modulefiles
module load anaconda3.6

## tool, marvel 
marvel_dir=/users/PAS1117/osu7810/software/MARVEL_v0.2_202002
cd $marvel_dir


## run marvel_v0.1
python marvel_bins.py -i $outputDir/split_sequences -t $threads_No


## clean directory
cd $outputDir/split_sequences/results/; tar -zcf hmmscan.tar.gz hmmscan; rm -r hmmscan; tar -zcf prokka.tar.gz prokka; rm -r prokka
cd $outputDir/split_sequences/; tar -zcf split_contigs.tar.gz *.fasta; rm *.fasta
cd $outputDir; mv $outputDir/split_sequences/split_contigs.tar.gz .; mv $outputDir/split_sequences/results/* .
rm -r $outputDir/split_sequences
