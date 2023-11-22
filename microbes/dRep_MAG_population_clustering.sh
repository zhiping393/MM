#!/bin/bash



## can run on pitzer or owens; only module works, sigularity does not work
## need to change 3 inputs: 1) workDir=, 2) input_MAG_folder=, and 3) file_type=


## working directory  %%% need to change
workDir=~/working_folder/
cd $workDir

## module load
module use /fs/project/PAS1117/modulefiles
module load dRep/1.0.0


## input folder with MAGs -- need change %%%%%%%%%%%%%
input_MAG_folder=MAGs_all_99


## file type
file_type=fa


## run dRep dereplicate (pramary cluster ANI -pa 0.80; second cluster ANI -sa 0.97; coverage -nc 0.7; sequence length >1M; cluster algorithm ANImf)
dRep dereplicate_wf $workDir -g ${input_MAG_folder}/*.${file_type} --skipCheckM -pa 0.80 -sa 0.97 -nc 0.7 -l 1000000 --S_algorithm ANImf

