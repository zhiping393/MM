#!/bin/bash



## working directory  %%% need to change
workDir=~/working_folder/
cd $workDir

## genome directory
genomeDir=MAGs_all_99

## genome file extension
genomeEx=fa

## thread number
threadnumber=10

## tool
module use /fs/project/PAS1117/zhiping/software/1_modules/modulefiles
module load anaconda3.6
source activate checkM

## run checkM to check genome quality
checkm lineage_wf -t $threadnumber -x $genomeEx $genomeDir ${workDir}/02_checkm_out


