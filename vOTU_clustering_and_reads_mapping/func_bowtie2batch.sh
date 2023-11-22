#!/bin/bash

## help message
usage() {
echo -e "
This script uses contig file and path of QC reads as inputs, to generate bam files and abundance table. **It only works with interleaved paired reads**
    output files are in the same folder where the input reference contig file is: 
        1) bamfiles: 01_bam_files_or/
        2) sorted bamfiles: 01_bam_files_sort
        3) abundance table: Read2RefMapper_output_95-75-70/coverage_table.csv (if requested '-a yes')


Required arguments:
-f      input contig file used as references (genome, fasta format)

-p      path of QC_reads files (The files are compressed and in '.fastq.gz' format; e.g., sample_1.fasta.gz, sample_2.fastq.gz)

Optional arguments:
-a      generate abundance table (yes or no; default: yes)

-h, --help   show this help message
"
}

if [ -z "$1" ] || [[ $1 == -h ]] || [[ $1 == --help ]]; then
  usage
  exit 1
fi

## determine if the 1st argument is start with "-"
head=${1:0:1}
if [[ $head != - ]]; then
  echo "syntax error. You need an argument"
  usage
  exit 1
fi

## arguments, variables, and default values
abundance_table="yes"
while getopts "f:p:a:" opt
do
  case $opt in
    f)
        input_contig_file=$OPTARG;;

    p) 
        path_QC=$OPTARG;;

    a)  abundance_table=$OPTARG;;

    \?)
        echo "invalid argument"
        exit 1;;
  esac
done


## path of base working directory
path_input=$(readlink -f $input_contig_file)
workDir=${path_input%/*}
cd $workDir

## input files: reference contig file + directory containing QC reads files
input_cont=$path_input
QC_dir=$path_QC  


## module load all softwares
module use /users/PAS1117/osu7810/local/share/modulefiles
module load bowtie2/2.3.4.3
module load samtools/1.9

module use /fs/project/PAS1117/zhiping/software/1_modules/modulefiles
module load anaconda3.6
source activate python27


## determine if format of QC read files are right
sample_num=$(ls $QC_dir | grep -c '.fastq.gz')

if [ $sample_num -eq 0 ]; then
	echo "No QC_reads file (e.g., sample_1.fastq.gz) was found, please check if the path is correct: ${QC_dir}"
	echo "Notes: The QC_reads files should be compressed files and end with '.fastq.gz'"
	exit 1
else
	echo "QC files were detected: ${QC_dir}"
fi

## make Bowtie database
cont_name=${input_cont##*/} # will be "contigfile.fna"
db_name=${cont_name%.*} # will be "contigfile"

mkdir bowtie2-db
bowtie2-build -f $input_cont bowtie2-db/$db_name


## run bowtie2 to generate bam files parallelly
func_bowtie2 () {
	local input=$1

	QC_name_tem=${input##*/}
	QC_name=${QC_name_tem%.gz*}
	
	zcat $input > $QC_name
	
	bowtie2 -q --phred33 --end-to-end --sensitive -p 12 -I 0 -X 2000 --no-unal -x bowtie2-db/$db_name --interleaved $QC_name | samtools view -Sb - > ${QC_name}.bam
	samtools sort ${QC_name}.bam -o ${QC_name}_sort.bam
  echo -e "Above sample: ${QC_name_tem}\n\n"

	rm $QC_name
}

for input in ${QC_dir}/*.fastq.gz; do 
	func_bowtie2 "$input" & 
done
wait

## move all .bam files into the folder called bam_files
mkdir 01_bam_files_or
mkdir 01_bam_files_sort

mv *_sort.bam 01_bam_files_sort
mv *.bam 01_bam_files_or


## decide if generate abundance table (yes or no; default: yes)
if [ $abundance_table == "no" ]; then
	echo "bam files were generated; No abundance table was generated"
	echo "use the option '-a yes' if you want to generate abundance table; Note: it will filter mapped reads using '95% ID + 75% read coverage + 70% contig coverage'"
	exit 0
else
	echo "now using Read2RefMapper to generate abundance table."
fi

## Read2RefMapper to generate abundance table
#load the softwares
module load singularity
module use /fs/project/PAS1117/modulefiles
module load singularityImages

# --percent-id 0.95 the identity; --percent-aln 0.75 coverage of reads 75%; --cov_filter 70 coverage of contig 70%
mkdir ${workDir}/Read2RefMapper_output_95-75-70
mkdir ${workDir}/Read2RefMapper_output_95-75-60
mkdir ${workDir}/Read2RefMapper_output_95-75-50


cd ${workDir}/Read2RefMapper_output_95-75-70
Read2RefMapper-1.1.1.simg --dir ${workDir}/01_bam_files_or --coverage-mode tpmean --num-threads 4 --percent-id 0.95 --percent-aln 0.75  --cov_filter 70

cd ${workDir}/Read2RefMapper_output_95-75-60
Read2RefMapper-1.1.1.simg --dir ${workDir}/01_bam_files_or --coverage-mode tpmean --num-threads 4 --percent-id 0.95 --percent-aln 0.75  --cov_filter 60

cd ${workDir}/Read2RefMapper_output_95-75-50
Read2RefMapper-1.1.1.simg --dir ${workDir}/01_bam_files_or --coverage-mode tpmean --num-threads 4 --percent-id 0.95 --percent-aln 0.75  --cov_filter 50
