#!/bin/bash



#**********************************************************************************************************************************************
# This script only works with compressed & matepaired reads
#
# It ombines "bowtie2 + samtools + Read2RefMapper" to generate bam files + abundance table, outputs will be in the folder where $input_cont is
#
# need to change 2 inputs: 1) input_cont= and 2) QC_dir=
#**********************************************************************************************************************************************



## input contig file used as reference contigs   %%%%%%  need to change
input_cont=virus_contigs_95-80.fna

## path of QC_reads files  %%%%%% need to change
QC_dir=${workDir}/QC-Reads   # the directory to the fastq files, interleaved paired-end reads

## run bowtie2
sh func_bowtie2batch.sh -f $input_cont -p $QC_dir
