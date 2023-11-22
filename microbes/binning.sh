#!/bin/bash


## working directory  %%% need to change
workDir=~/working_folder/
cd $workDir

## 
metabat2 --seed 12345 -t 40 --minContig {mincontigsize} -i {input.scaffold} -a {input.depth} --maxP {params.maxP} --maxEdges {params.maxEdges} --minS {params.minS}  -o {base.file.name} 

