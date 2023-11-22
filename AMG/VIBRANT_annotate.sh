#!/bin/bash



##################################################################################
## This VIBRANT script was modified for annotating all input contigs, inlcuding
## those won't be identified as viruses.
##
## Don't use this script for identifying viral contigs; only for annotation
##
##
## change three inputs: 1) workDir=; 2) input_cont=; and 3) thread_number=
##
#################################################################################



## load softwares
module use /fs/project/PAS1117/modulefiles
module load VIBRANT/1.2.1 

## working directory  %%% need to change
workDir=~/working_folder/
cd $workDir

## input fasta file
input_cont=${workDir}/virus_contigs.fna

## thread_number
thread_number=20

## names
name_input_cont_tem=${input_cont##*/}
name_input_cont=${name_input_cont_tem%.*}

## run vibrant
python VIBRANT_run.py -i $input_cont -t $thread_number -l 500 -o 1 -virome -folder output_VIBRANT_Annotation_${name_input_cont} -d /fs/project/PAS1117/modules/VIBRANT/VIBRANT/databases/ -m /fs/project/PAS1117/modules/VIBRANT/VIBRANT/files


