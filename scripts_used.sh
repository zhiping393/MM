#!/bin/bash



## Fastq reads download 
accession_ID_SRA=xxx # e.g., accession_ID_SRA=SRR8709623 (A marine sediment metagenome: https://www.ncbi.nlm.nih.gov/sra/?term=SRR8709623)
sample_name=marine_sediment_${accession_ID_SRA}

sh sratoolkit.2.10.5-ubuntu64/bin/fastq-dump --gzip --skip-technical --readids --read-filter pass --dumpbase --split-e --clip $accession_ID_SRA
mv ${ccession_ID_SRA}_pass_1.fastq.gz ${sample_name}_R1.fastq.gz # R1 of paired end reads
mv ${ccession_ID_SRA}_pass_2.fastq.gz ${sample_name}_R2.fastq.gz # R2 of paired end reads


## quality control 
java -jar /Trimmomatic-0.36/trimmomatic-0.36.jar PE -phred33 ${sample_name}_R1.fastq.gz ${sample_name}_R2.fastq.gz ${sample_name}_QC_R1.fastq.gz ${sample_name}_unpair_R1.fastq.gz ${sample_name}_QC_R2.fastq.gz ${sample_name}_unpair_R2.fastq.gz ILLUMINACLIP:${adapter_file}:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:20 MINLEN:50


## merge to interleaved paired-end reads
sh /bbmap_38.43/reformat.sh in1=${sample_name}_QC_R1.fastq.gz in2=${sample_name}_QC_R2.fastq.gz out=${sample_name}_QC_interleaved.fastq.gz


## reads deduplication 
sh bbmap_38.43/clumpify.sh in=${sample_name}_QC_interleaved.fastq.gz out=${sample_name}_QC_interleaved_deduped.fastq.gz dedupe subs=0 passes=2


## assembly via spades.
python spades.py --sc -k 21,33,55,77,99,127 --12 ${sample_name}_QC_interleaved_deduped.fastq.gz -o ouput_assembly_${sample_name} # this step will generate assembled contigs >=500 bp, contigs.fasta


## select contigs >=1.5kb for further virus identification
sh func_length-cut.sh -i contigs.fasta -l 1500 # a custom script to extract sequences in a specific lenght range (e.g., >=1.5 kb here), it will generate a file named as 'contigs_1.5kb.fasta' 


## virus identification
input_cont=contigs_1.5kb.fasta

# VirSorter for virome
wrapper_phage_contigs_sorter_iPlant.pl -f $input_cont --db 2 --virome --wdir output_virsorter_virome --ncpu 20 --data-dir /fs/project/PAS1117/modules/virsorter/1.1.0/databases/virsorter-data/
# VirSorter for microbial or bulk metagenomes
wrapper_phage_contigs_sorter_iPlant.pl -f $input_cont --db 2 --wdir output_virsorter_metagenome --ncpu 20 --data-dir /fs/project/PAS1117/modules/virsorter/1.1.0/databases/virsorter-data/

# DeepVirFinder
dvf.py -i $input_cont -o output_deepvirfinder -l 1 -c 40

# MARVEL
func_split_contigs.sh -i $input_cont -n 1 -o output_folder_split # a custom script to split sequences
python marvel_bins.py -i output_folder_split -t 20


## summarize and dereplicate viral contigs identified from the above three tools
input_deepvirfinder=gt1bp_dvfpred.txt # output document from DeepVirFinder
input_marvel=log-file_MARVEL_contigs_1.5kb.o858052 # the output log file from MARVEL
input_virsorter=output_virsorter_virome # the ourput folder of virsorter
sh func_combine_virus_VS-DVF-MV.sh -i $input_cont -d $input_deepvirfinder -m $input_marvel -v $input_virsorter # a custom script to combine and dereplicate viral contigs identified by the above 3 tools using the parameters specified in the manuscript. It generated a output file named "virus_all_DVF-MV-VS.fasta"


## annote viral contigs
python VIBRANT_run.py -i virus_all_DVF-MV-VS.fasta -t 20 -l 500 -o 1 -virome -folder output_VIBRANT_Annotation -d /PATH/TO/VIBRANT/databases/ -m /PATH/TO/VIBRANT/modelfiles


## cluter vOTUs 
Cluster_genomes.pl -f virus_all_DVF-MV-VS.fasta -c 80 -i 95 # a iVirus script to cluter viral contigs into vOTUs if they shared ≥95% nucleotide identity across 80% of their lengths. It will generate a document "virus_all_DVF-MV-VS_95-80_seeds.fna" that contains all vOTUs sequences. 
sh func_length-cut.sh -i virus_all_DVF-MV-VS_95-80_seeds.fna -l 10000 # select vOTUs >=10 kb; it will generate a file named as 'virus_all_DVF-MV-VS_95-80_seeds_10.0kb.fna' 


## viral genome quality assessment
checkv contamination virus_all_DVF-MV-VS_95-80_seeds.fna outputDir -t 20
checkv completeness virus_all_DVF-MV-VS_95-80_seeds.fna outputDir -t 20
checkv terminal_repeats virus_all_DVF-MV-VS_95-80_seeds.fna outputDir 
checkv quality_summary virus_all_DVF-MV-VS_95-80_seeds.fna outputDir 


## host prediction
VirMatcher -v virus_all_DVF-MV-VS_95-80_seeds.fna --archaea-host-dir /PATH/TO/ARCHAEAL/HOST/database --archaea-taxonomy gtdbtk_archaeal_taxonomy.tsv --bacteria-host-dir /PATH/TO/BACTERIAL/HOST/database --bacteria-taxonomy gtdbtk_bacterial_taxonomy.tsv -t 4 -o output_folder --python-aggregator


## taxonomic assignment
input_cont=all_contigs_virus_10.0kb_95-80.fna
virus_db="ProkaryoticViralRefSeq201-Merged"
path_input_cont=$(readlink -f $input_cont)
name_input_cont_tem=${path_input_cont##*/}
name_input_cont=${name_input_cont_tem%.*}
workDir=${path_input_cont%/*}
cd $workDir
export PATH=/users/PAS1117/osu7810/functions:$PATH
module load singularity/current
module use /fs/project/PAS1117/modulefiles
module load singularityImages
/fs/project/PAS1117/bioinformatic_tools/Prodigal2.6.1/prodigal -i $path_input_cont -p meta -a ${name_input_cont}.faa
sh /users/PAS1117/osu7810/functions/func_vcontact2_genome2gene-file_prodigal.sh -i ${name_input_cont}.faa
input_raw_prots_file=${workDir}/${name_input_cont}_vcontact_prot.faa
input_genome2gene_file=${workDir}/genome2gene-file_prodigal.csv
vConTACT2-0.9.20.sif --raw-proteins $input_raw_prots_file --proteins-fp $input_genome2gene_file --rel-mode Diamond --db $virus_db --pcs-mode MCL --vcs-mode ClusterONE --c1-bin /fs/project/PAS1117/zhiping/software/cluster_one-1.0.jar --threads 20 --max-overlap 0.8 --vc-overlap 0.9 --penalty 2 --vc-haircut 0.65 --min-density 0.3 --min-size 2 --merge-method single --similarity match --seed-method nodes --output-dir output_vcontact2 -f


## reads mapping and abundance calculation
mkdir bowtie2-db
bowtie2-build -f virus_all_DVF-MV-VS_95-80_seeds.fna bowtie2-db/virus_all_DVF-MV-VS_95-80_seeds
bowtie2 -q --phred33 --end-to-end --sensitive -p 12 -I 0 -X 2000 --no-unal -x bowtie2-db/virus_all_DVF-MV-VS_95-80_seeds --interleaved ${sample_name}_QC_interleaved.fastq.gz | samtools view -Sb - > ${sample_name}_QC_interleaved.bam
Read2RefMapper-1.1.1.simg --dir /PATH/TO/BAM/FILEs --coverage-mode tpmean --num-threads 10 --percent-id 0.95 --percent-aln 0.75  --cov_filter 70 # a iVirus script to generate the abundance table "coverage_table.csv"


## MAG quality assessment
genome_extention=fna # extention of MAGs: fna
checkm lineage_wf -t 20 -x $genome_extention /PATH/TO/input/genomes output_directory_checkm


## MAG taxonomy assignment 
gtdbtk classify_wf -x $genome_extention --cpus 20 --genome_dir /PATH/TO/input/genomes --out_dir output_directory_taxonomy


## MAG population clustering
dRep dereplicate_wf /PATH/TO/WORKING/DIRECTORY -g /PATH/TO/input/genomes/*.fna --skipCheckM -pa 0.80 -sa 0.95 -nc 0.1 -l 1000000 --S_algorithm ANImf


## MAG reads mapping and abundance calculation
coverm genome --genome-fasta-directory $input_MAG_dir -x $genome_extention -p minimap2-sr -r /PATH/TO/COMBINED/genomes --interleaved /PATH/TO/INTERLEAVED/PAIRED-ED/QC/READS --bam-file-cache-directory output_bam-files -t 20 --min-read-percent-identity 0.95 --min-read-aligned-percent 0.75 --min-covered-fraction 0.40 --trim-min 0.05 -m mean trimmed_mean relative_abundance --output-format dense > trim-mean-relative_abundance.csv

## MAG annotation
DRAM.py annotate -i '/PATH/TO/GENOMES/*.fna' -o output_annotation --threads 40 --skip_uniref
DRAM.py distill -i output_annotation/annotations.tsv --rrna_path output_annotation/rrnas.tsv --trna_path output_annotation/trnas.tsv -o output_annotation/summaries 


## AMG phylogenetic tree
mafft --reorder --bl 30 --op 1.0 --maxiterate 1000 --retree 1 --genafpair --quiet $input_file > ${workDir}/${input_gene_name_1}_aligned.fa
trimal -in ${workDir}/${input_gene_name_1}_aligned.fa -out ${workDir}/${input_gene_name_1}_aligned_trim.fa -gappyout
iqtree -s ${workDir}/${input_gene_name_1}_aligned_trim.fa -m MFP -bb 1000 -alrt 1000 -redo > log.txt



