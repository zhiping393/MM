#!/bin/bash


## working directory   %%% need to change
workDir=~/working_folder/
cd $workDir

func_trimomatic_filter () {
	local input_interleave=$1

	name_tem=${input_interleave##*/}
	name=${name_tem%_interleaved_reads.fastq.gz*}


	## splite reads
	sh /fs/project/PAS1117/zhiping/software/bbmap_38.43/reformat.sh in=${input_interleave} out1=${name}_interleaved_reads_R1.fastq.gz out2=${name}_interleaved_reads_R2.fastq.gz

	input_fastq_r1=${workDir}/${name}_interleaved_reads_R1.fastq.gz
	input_fastq_r2=${workDir}/${name}_interleaved_reads_R2.fastq.gz


	## output files 
	output_fastq_r1_pair=${workDir}/${name}_R1_pair.fastq.gz
	output_fastq_r1_unpair=${workDir}/${name}_R1_unpair.fastq.gz

	output_fastq_r2_pair=${workDir}/${name}_R2_pair.fastq.gz
	output_fastq_r2_unpair=${workDir}/${name}_R2_unpair.fastq.gz

	## adapter file
	adapter_file=/users/PAS1117/osu7810/software/Trimmomatic-0.36/Nextera_adapter_PE.fa


	## run trimommatic
	java -jar /users/PAS1117/osu7810/software/Trimmomatic-0.36/trimmomatic-0.36.jar PE -phred33 $input_fastq_r1 $input_fastq_r2 $output_fastq_r1_pair $output_fastq_r1_unpair $output_fastq_r2_pair $output_fastq_r2_unpair ILLUMINACLIP:${adapter_file}:2:30:10 LEADING:3 TRAILING:3 SLIDINGWINDOW:4:20 MINLEN:50

	## merge to interleaved reads
	sh /fs/project/PAS1117/zhiping/software/bbmap_38.43/reformat.sh in1=$output_fastq_r1_pair in2=$output_fastq_r2_pair out=${workDir}/${name}_interleaved_reads_QC.fastq.gz

}


for input_interleave in ${workDir}/*fastq.gz
do
	func_trimomatic_filter "$input_interleave" & 
done
wait

