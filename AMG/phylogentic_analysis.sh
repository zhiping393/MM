#!/bin/bash


## working directory  %%% need to change
workDir=~/working_folder/
cd $workDir

## input file with aa sequence of the target gene
input_pro=${workDir}/target_gene.faa

## number of genes for generating tree
gene_num=40

## run script, a pipelien to run blastp to search closely related genes, run mafft to align, run trimA to trim alignment, run iqtree to get the phylogenetic tree
sh func_phylogeny.sh -i $input_pro -n $gene_num
