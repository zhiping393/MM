#!/bin/bash


## working directory  %%% need to change
workDir=~/working_folder/
cd $workDir

## input virus information from DeepVirFinder, MARVEL, and VIRSorter
input_deepvirfinder=gt1bp_dvfpred.txt # output document from DeepVirFinder
input_marvel=log-file_MARVEL_contigs_1.5kb.o858052 # the output log file from MARVEL
input_virsorter=output_virsorter_virome # the ourput folder of virsorter

## combine
sh func_combine_virus_VS-DVF-MV.sh -i $input_cont -d $input_deepvirfinder -m $input_marvel -v $input_virsorter # a custom script to combine and dereplicate viral contigs identified by the above 3 tools using the parameters specified in the manuscript. It generated a output file named "virus_all_DVF-MV-VS.fasta"

