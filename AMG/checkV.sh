#!/bin/bash


#########################################################################
## 34.7 M data (3146 vOTUs), it takes only 8 min time and 2.1 Gb memory
##
##
##
#########################################################################

## working directory  %%%%%% need to change
workDir=~/working_folder/
cd $workDir

## input contig (single genome)    %%%%%% need change
input_cont=${workDir}/virus_contigs.fasta

## core number    %%%%%% may need change
thread_num=5

## names
input_cont_name_tem=${input_cont##*/}
input_cont_name=${input_cont_name_tem%.*}

## output folder
outputDir=${workDir}/output_checkV_${input_cont_name}
mkdir $outputDir


## load tools
module load singularity/current
module use /fs/project/PAS1117/modulefiles
module load singularityImages

## run checkV
CheckV-2020.04.27.sif contamination $input_cont $outputDir -t $thread_num
CheckV-2020.04.27.sif completeness $input_cont $outputDir -t $thread_num
CheckV-2020.04.27.sif terminal_repeats $input_cont $outputDir 
CheckV-2020.04.27.sif quality_summary $input_cont $outputDir 
