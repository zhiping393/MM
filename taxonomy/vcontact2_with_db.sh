#PBS -l walltime=120:00:00
#PBS -l nodes=1:ppn=20
#PBS -N taxonomy_vc
#PBS -m ae
#PBS -S /bin/bash
#PBS -j oe
#PBS -A PAS1117

########################################################################################
## this script will generate the genome2gene file and then get vcontact2 outputs
##
## need to change 2 inputs: 1) input_cont= and 2) virus_db=
##
## $input_cont is the file containing the genome DNA sequences of all viral contigs
#########################################################################################

## input genome DNA file  %%%%%% need to change; if this file is too large, you can split first and run comparison to db viruses individualy, and then select the associated viruses to run vcontact again without db to make networks that only contains associated viruses
input_cont=virus_contigs.fna

## database  %%%%%% need to change
virus_db="ProkaryoticViralRefSeq201-Merged"

## names
path_input_cont=$(readlink -f $input_cont)
name_input_cont_tem=${path_input_cont##*/}
name_input_cont=${name_input_cont_tem%.*}

workDir=${path_input_cont%/*}
cd $workDir

## tools
export PATH=/users/PAS1117/osu7810/functions:$PATH
module load singularity/current
module use /fs/project/PAS1117/modulefiles
module load singularityImages


## get protein file
Prodigal2.6.1/prodigal -i $path_input_cont -p meta -a ${name_input_cont}.faa

## get genome2gene file, this script will generate two files: *_vcontact_prot.faa and *_genome2gene-file_prodigal.csv
sh func_vcontact2_genome2gene-file_prodigal.sh -i ${name_input_cont}.faa

# input files for vcontact2
input_raw_prots_file=${workDir}/${name_input_cont}_vcontact_prot.faa
input_genome2gene_file=${workDir}/${name_input_cont}_genome2gene-file_prodigal.csv

# run vcontact2
vConTACT2-0.9.20.sif --raw-proteins $input_raw_prots_file --proteins-fp $input_genome2gene_file --rel-mode Diamond --db $virus_db --pcs-mode MCL --vcs-mode ClusterONE --c1-bin /fs/project/PAS1117/zhiping/software/cluster_one-1.0.jar --threads 20 --max-overlap 0.8 --vc-overlap 0.9 --penalty 2 --vc-haircut 0.65 --min-density 0.3 --min-size 2 --merge-method single --similarity match --seed-method nodes --output-dir output_vcontact2 -f
