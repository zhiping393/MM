#!/bin/bash


#######on pitzer; if on owens, change "ppn=28" and "-t 28" when running metabate2
#Set up bowtie2-samtools-metabat2 commands

## working directory 
workDir=~/working_folder/
cd $workDir

## input contigs
input_cont=${workDir}/contigs.fasta

## input fastq file, interleaved paired-end reads
input_QC=${workDir}/sample.fastq.gz


## names
sample_name_tem=${input_QC##*/}
sample_name=${sample_name_tem%.fastq*}

cont_name_tem=${input_cont##*/}
cont_name=${cont_name_tem%.*}


## working in $TMPDIR
#documents needed include reference sequences used for database and the QC reads
cp $input_cont $TMPDIR
cp $input_QC $TMPDIR

cd $TMPDIR

#load the softwares needed for analyzing including python, bowtie2 and samtools
module use /users/PAS1117/osu7810/local/share/modulefiles
module load bowtie2/2.3.4.3
module load metabat/2.12.1

module use /users/PAS1117/osu9664/modulefiles
module load samtools/1.3.1
module load python/anaconda2




#decompress the QC reads
zcat $sample_name_tem > ${sample_name}.fastq

#make a new folder for the database and build the database
mkdir bowtie2-db
bowtie2-build -f $cont_name_tem bowtie2-db/${cont_name}


#use bowtie2 and samtools to aligh each QC_read file to the database
bowtie2 -q --phred33 --end-to-end --sensitive -p 12 -I 0 -X 2000 --no-unal -x bowtie2-db/${cont_name} --interleaved ${sample_name}.fastq | samtools view -Sb - > ${sample_name}.bam

#use samtools to sort the bam file
samtools sort ${sample_name}.bam -o ${sample_name}_sorted.bam

#using metabate2
mkdir bin_output
jgi_summarize_bam_contig_depths --outputDepth depth.txt ${sample_name}_sorted.bam
# metabat2 -i $cont_name_tem -a depth.txt -m 1500 -s 10000 -t 40 -o bin_output/bin_${sample_name}
#run metabat with different parameters from very stringent to very sensitive
metabat2 --seed 12345 -t 40 --minContig 1500 -i $cont_name_tem -o  bin_output/bin_${sample_name}_CompOnly
metabat2 --seed 12345 -t 40 --minContig 1500 -i $cont_name_tem -a depth.txt --maxP 50 --maxEdges 100 --minS 99 -o bin_output/bin_${sample_name}_SuperStringent
metabat2 --seed 12345 -t 40 --minContig 1500 -i $cont_name_tem -a depth.txt --maxP 95 --maxEdges 200 --minS 60 -o bin_output/bin_${sample_name}_StandardNoAdd --noAdd
metabat2 --seed 12345 -t 40 --minContig 1500 -i $cont_name_tem -a depth.txt --maxP 95 --maxEdges 200 --minS 60 -o bin_output/bin_${sample_name}_Standard
metabat2 --seed 12345 -t 40 --minContig 1500 -i $cont_name_tem -a depth.txt --maxP 95 --maxEdges 500 --minS 60 -o bin_output/bin_${sample_name}_Sensitive
metabat2 --seed 12345 -t 40 --minContig 1500 -i $cont_name_tem -a depth.txt --maxP 99 --maxEdges 500 --minS 60 -o bin_output/bin_${sample_name}_SuperSensitive


#get the files produced that you need
cp * $workDir
cp -r * $workDir

