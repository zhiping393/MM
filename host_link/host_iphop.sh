#!/bin/bash


## working directory  %%% need to change
workDir=~/working_folder/
cd $workDir

## input viral contigs   %%%%%%  need to change
input_viral_cont=${workDir}/virus_contigs.fasta

## iphop's database   %%%%%%  need to change
db_path=iphop/database/Sept_2021_pub_rw

## thread number  %%%%%%  may need to change 
thread_num=10

## tools
module use /fs/project/PAS1117/modulefiles
module load iPHoP

## run iPHoP - download the database
# iphop download --db_dir ${workDir}/database --no_prompt
iphop predict --fa_file $input_viral_cont --db_dir $db_path --out_dir output_iphop_score-90 --num_threads $thread_num --min_score 90
iphop predict --fa_file $input_viral_cont --db_dir $db_path --out_dir output_iphop_score-75 --num_threads $thread_num --min_score 75
