#!/bin/bash


## loop, run on terminal, *.fastq.gz are interleaved paired end reads
# for input in *fastq.gz; do qsub -v input_QC=$input assembly.sh; done


## working directory
workDir=~/working_folder/
cd $workDir

## sample name
sample_name=${input%.fastq*}

## reads deduplication 
sh bbmap_38.43/clumpify.sh in=${sample_name}.fastq.gz out=${sample_name}_deduped.fastq.gz dedupe subs=0 passes=2


## assembly via spades.
python spades.py --sc -k 21,33,55,77,99,127 --12 ${sample_name}_deduped.fastq.gz -o ouput_assembly_${sample_name} # this step will generate assembled contigs >=500 bp, contigs.fasta


## select contigs >=1.5kb or >=1.0kb for further virus identification or other analyses
sh func_length-cut.sh -i contigs.fasta -l 1500 # a custom script to extract sequences in a specific lenght range (e.g., >=1.5 kb here), it will generate a file named as 'contigs_1.5kb.fasta' 
sh func_length-cut.sh -i contigs.fasta -l 1000 # it will generate a file named as 'contigs_1.0kb.fasta' 

