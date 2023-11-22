#!/bin/bash



#######################################################################
## this script annotates MAGs using dram
## 221 MAGs took 19 hours with 20 cores on pitzer
## need to change inputs: 1) workDir, 2) inputBin=
#######################################################################

## working directory  %%% need to change
workDir=~/working_folder/
cd $workDir

## load software
module use /fs/project/PAS1117/modulefiles
module load DRAM


## run dram annotation %%%%%% need to change "-i"
DRAM.py annotate -i 'bins/*.fna' -o ${workDir}/output_annotation --threads 20 --skip_uniref

## run dram distill
DRAM.py distill -i ${workDir}/output_annotation/annotations.tsv --rrna_path ${workDir}/output_annotation/rrnas.tsv --trna_path ${workDir}/output_annotation/trnas.tsv -o ${workDir}/output_genome_summaries 

