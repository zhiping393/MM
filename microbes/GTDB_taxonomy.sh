#!/bin/bash



## working directory  %%% need to change
workDir=~/working_folder/
cd $workDir


## MAGs directory %%%%%% need change
binDir=MAGs_all_99

## MAGs extension  %%%%%% need change
bin_ext=fa


## tools
module use /fs/project/PAS1117/zhiping/software/1_modules/modulefiles
module load anaconda3.6 
source activate gtdbtk-1.3.0


## run GDTB
gtdbtk classify_wf -x $bin_ext --cpus 40 --genome_dir $binDir --out_dir bins_taxonomy

