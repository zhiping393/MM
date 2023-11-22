#!/bin/bash

## loop
# for input_cont in *_contigs_1.5kb.fasta; do name=${input_cont##*/}; sample_name=${name%_contigs_1.5kb.fasta*}; qsub -v input_cont=$input_cont,sample_name=$sample_name virus_ID_VIRSorter-1.1.0_microbiome.sh; done

## working directory  %%% need to change
workDir=~/working_folder/
cd $workDir

## input contig file  %%% need to change
# input_cont=${workDir}/contigs_1.5kb.fasta

##Load softwares
module use /fs/project/PAS1117/modulefiles
module load virsorter/1.1.0

###run VIRSORTER
wrapper_phage_contigs_sorter_iPlant.pl -f $input_cont --db 2 --wdir output_virsorter_${sample_name} --ncpu 15 --data-dir /fs/project/PAS1117/modules/virsorter/1.1.0/databases/virsorter-data/
