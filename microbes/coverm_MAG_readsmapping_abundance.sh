#!/bin/bash



#######################################################################################################################################
## this script could map (interleaved) QC reads to MAGs to generated the bam files, and then calculate the (trimmed) coverages and
## relative abundance of each MAG in every samples.
## change 4 inputs: 1) workDir=, 2) input_MAG_dir=, 3) MAG_ext=, 4) mapping_cont=, 5) input_QC=, and 6) threadsNo=
##
########################################################################################################################################

## software
module use /fs/project/PAS1117/zhiping/software/1_modules/modulefiles
module load anaconda3.6
source activate coverm


## working directory  %%% need to change
workDir=~/working_folder/
cd $workDir

## the directory with all MAGs & extension of MAGs (this is actually used to distinguish what contigs belonged to what MAGs, not used for mapping)   %%%%%% need to change
input_MAG_dir=MAGs_all_99
MAG_ext=fa

## fasta file with combined contigs of all MAGs in input_MAG_dir (this combined fasta sequences were used for reads mapping, do NOT put it in the same folder as input_MAG_dir)   %%%%%%   need to change
cat MAGs_all_99/*.fa > bins_combined_all.fasta
mapping_cont=MAGs_all_99/bins_combined_all.fasta


## input (interleaved) QC reads for mapping to conbined sequences   %%%%%% need to change 
input_QC=QC-reads/*.fastq.gz

## nunber of cores to run the script %%%%%% need to change (optional)
threadsNo=20

## run coverm: min-read-percent-identity 0.95 the identity of reads 95%; --min-read-aligned-percent 0.75 coverage of reads 75%; --min-covered-fraction 0.40 coverage of MAG 40%; --trim-min 0.05 remove the highest 5% and lowest 5% coverage of positions - default value is 5%;
coverm genome --genome-fasta-directory $input_MAG_dir -x $MAG_ext -p minimap2-sr -r $mapping_cont --interleaved $input_QC --bam-file-cache-directory ${workDir}/bam-files -t $threadsNo --min-read-percent-identity 0.95 --min-read-aligned-percent 0.75 --min-covered-fraction 0.40 --trim-min 0.05 -m mean trimmed_mean relative_abundance --output-format dense > trim-mean-relative_abundance.csv
