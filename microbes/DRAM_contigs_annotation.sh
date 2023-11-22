#!/bin/bash



##############################################################################
## This script uses dram to annotate contigs - combine all contigs to one file
##
## need to change inputs: 1) workDir, 2) inputBin=
##############################################################################


## working directory  %%% need to change
workDir=~/working_folder/
cd $workDir


## load software
module use /fs/project/PAS1117/modulefiles
module load DRAM


## input file - combine all (short) contigs together %%%%%% need change
input_contig=contigs_combined.fasta

## change input contig file name
cp $input_contig ${workDir}/combine_contig.fasta

## run dram annotation %%%%%% need to change "-i"
DRAM.py annotate -i ${workDir}/combine_contig.fasta -o ${workDir}/output_annotation --threads 20

## run dram distill
DRAM.py distill -i ${workDir}/output_annotation/annotations.tsv --rrna_path ${workDir}/output_annotation/rrnas.tsv -o ${workDir}/output_genome_summaries 
