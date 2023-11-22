#!/bin/bash


###*********************************************************************************
### DVF needs high memory, so prefer to use pitzer with 40 nodes (183 Gb memory)   *
### Need to change two inputs: 1) workDir= and 2) input_cont=                          *
###*********************************************************************************

## loop, run on terminal to submit multiple jobs at tone time
# for input_cont in *_contigs_1.5kb.fasta; do name=${input_cont##*/}; sample_name=${name%_contigs_1.5kb.fasta*}; qsub -v input_cont=$input_cont,sample_name=$sample_name virus_ID_DVF.sh; done

## working directory  %%% need to change
workDir=~/working_folder/
cd $workDir

## input contig file  %%% need to change
# input_cont=${workDir}/contigs_1.5kb.fasta

##Load softwares
module use /fs/project/PAS1117/modulefiles
module load DeepVirFinder/1.0

#run DVF
dvf.py -i $input_cont -o output_DVF_${sample_name} -l 1 -c 40
