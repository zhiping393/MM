#!/bin/bash



## working directory  %%% need to change
workDir=~/working_folder/
cd $workDir

## input viral contigs   %%%%%%  need to change
input_viral_cont=${workDir}/virus_combine_all-samples_5.0kb_95-80_seeds.fna

## input path to bacterial host genomes   %%%%%%  need to change
input_path_bacG=/fs/project/PAS1117/VranaLake/10_re-analysis/11_host_prediction/04_VirMatcher/01_host_genomes_bacteria

## input path to archaeal host genomes   %%%%%%  need to change
input_path_arcG=/fs/project/PAS1117/VranaLake/10_re-analysis/11_host_prediction/04_VirMatcher/01_host_genomes_archaea

## input taxonomy file to bacterial hosts   %%%%%%  need to change
input_taxa_bac=/fs/project/PAS1117/VranaLake/10_re-analysis/11_host_prediction/04_VirMatcher/hostTaxa-all_VirMatcher_bacteria.txt

## input taxonomy file to archaeal hosts   %%%%%%  need to change 
input_taxa_arc=/fs/project/PAS1117/VranaLake/10_re-analysis/11_host_prediction/04_VirMatcher/hostTaxa-all_VirMatcher_archaea.txt

## thread number  %%%%%%  may need to change 
thread_num=10


## tools
module use /fs/project/PAS1117/modulefiles
module load VirMatcher

## run VirMatcher
VirMatcher -v $input_viral_cont --archaea-host-dir ${input_path_arcG} --archaea-taxonomy $input_taxa_arc --bacteria-host-dir $input_path_bacG --bacteria-taxonomy $input_taxa_bac --threads $thread_num -o output_VirMatcher --python-aggregator

