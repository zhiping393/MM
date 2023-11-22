#!/bin/bash




## help message
usage() {
echo -e "
This script use the protein file and genbank file of a viral contigs to produce genome map file (as the input of EasyFig).
outputs: 1) *_blast_output_11_fmt6_firstHit_virus.tsv: it contains gene information by comparing to virsorter v1 database 
         2) *_new.gbk (if -g is True): it contains color information indicating 3 kind of genes inlcuding 'phage gene (orange, 255 128 0)',
         'Hallmark gene (blue, 0 0 255)', and 'unclassified gene (grey, 192 192 192)'. It can be used as input of EasyFig
         to draw genome map

Notes: The contig may need checkV to: assign the viral, assign microbial genes, identify the boundary of viral and mcirobial fragment

Required arguments:
-i      input protein file (from prodigal; clean titles). If both -g and -b are provided, -i is an optional argument.

Optional arguments:
-g      input genbank.gbk file (from sequin); If False, this script only does annotating.

-b      input blastp output file (one output file of this script if -b is not specified: *_firstHit_virus.tsv). We will used the color information in this file

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

while getopts "i:g:b:" opt
do
  case $opt in
    i)
        input_pro=$OPTARG;;

    g)
        input_genbank=$OPTARG;;

    b)
        input_blast_color=$OPTARG;;

    \?)
        echo "invalid argument"
        exit 1;;
  esac
done



## determine whether there is blast file as input

if [ -z "$input_blast_color" ]; then
  echo -e "\n\nThe option '-b' is not provided; So we will annotate the protein file."
else

	## path and names
	path_input=$(readlink -f $input_genbank)
	workDir=${path_input%/*}
	cd $workDir

	input_genbank_name_tem=${path_input##*/}
	input_genbank_name=${input_genbank_name_tem%.*}

  echo -e "Only modifying genbank file..."

	## modify the genbank file to add the color information
	cp $input_genbank ${input_genbank_name}_new.gbk
	line_count=1
	cat $input_genbank | grep "^     CDS" | while read line
	do 
		((line_count++))
		line_or=$(echo $line | cut -f2 -d " ")
		line_tem=$(cat $input_blast_color | sed -n ${line_count}p | cut -f 20)
		line_tem1='\'${line_tem}
		sed -i "s/     CDS             ${line_or}/     CDS             ${line_or}\n                     ${line_tem1}/g" ${input_genbank_name}_new.gbk
	done

	echo -e "Job done!! Only modify the genbank file\n"
	echo -e "\nOnly 1 output: \n   1) ${input_genbank_name}_new.gbk: it contains color information indicating 3 kind of genes inlcuding 'phage gene (orange, 255 128 0)', 
	'Hallmark gene (blue, 0 0 255)', and 'unclassified gene (grey, 192 192 192)'. It can be used as input of EasyFig to draw genome map\n"

	exit 0

fi



## path of base working directory
path_input=$(readlink -f $input_pro)
workDir=${path_input%/*}
cd $workDir


## tools
module load blast/2.13.0+
export PATH=/users/PAS1117/osu7810/functions:$PATH

## names
input_pro_name_tem=${input_pro##*/}
input_pro_name=${input_pro_name_tem%.*}


## virsoter database
balstp_db_virsorter=/fs/project/PAS1117/zhiping/1_database/10_VirSorter/01_db/phage_protein_14-03_RefseqABVir-plus-viromes
input_phage_cluster_file=/fs/project/PAS1117/zhiping/1_database/10_VirSorter/Phage_Clusters_current.tab


## input filles
input_blast_file=${input_pro_name}_blast_output_11_fmt6_firstHit.tsv

## names
input_blast_file_name_tem=${input_blast_file##*/}
input_blast_file_name=${input_blast_file_name_tem%.*}
input_genbank_name_tem=${input_genbank##*/}
input_genbank_name=${input_genbank_name_tem%.*}


## running blastp
echo -e "\nNow annotating..."
blastp -db $balstp_db_virsorter -outfmt 11 -query $path_input -out ${input_pro_name}_blast_output_11.tsv
func_blastn_add_header.sh -i ${input_pro_name}_blast_output_11.tsv

## get the first hit
head -1 ${input_pro_name}_blast_output_11_fmt6.tsv > ${input_pro_name}_blast_output_11_fmt6_firstHit.tsv

cat ${input_pro_name}_blast_output_11_fmt6.tsv | sed "1"d | cut -f1 | uniq | while read line
do 
	grep -w "${line}" ${input_pro_name}_blast_output_11_fmt6.tsv | head -1 >> ${input_pro_name}_blast_output_11_fmt6_firstHit.tsv
done








## generate virus informaiton file
echo "virus Hit" > ${input_blast_file_name}_virus_tem.tsv

cat $input_blast_file | sed "1"d | cut -f14 | while read line
do 
	e_num=$(echo $line | grep -c "e")
	if [ $e_num -ge 1 ]
	then
		decimal_e=$(echo $e_num | cut -f2 -d "e")
		if [ $decimal_e -le 4 ]
		then 
			echo -e "virus" >> ${input_blast_file_name}_virus_tem.tsv
		else 
			echo -e -e "-" >> ${input_blast_file_name}_virus_tem.tsv
		fi
	else 
		if (( $(echo "$line <= 0.001" | bc -l) ))
			then 
				echo -e "virus" >> ${input_blast_file_name}_virus_tem.tsv
			else echo -e "-" >> ${input_blast_file_name}_virus_tem.tsv
		fi
	fi
done

paste $input_blast_file ${input_blast_file_name}_virus_tem.tsv > ${input_blast_file_name}_virus.tsv
rm ${input_blast_file_name}_virus_tem.tsv



## add hallmark and annotation information
echo -e "Phage cluster hit #\tPhage cluster hit" > ${input_blast_file_name}_virus_tem.tsv
line_num=1
cat ${input_blast_file_name}_virus.tsv | sed "1"d | cut -f16 | while read line
do 
	((line_num+=1))
	line_info=$(cat ${input_blast_file_name}_virus.tsv | sed -n "${line_num}"p | cut -f3 | sed "s/\(.*\)|ref|\(.*\)|/\2/g")
	line_gene_name=$(cat ${input_blast_file_name}_virus.tsv | sed -n "${line_num}"p | cut -f1)


	if [ $line == "virus" ]
	then
		phage_cluter_hit_num=$(cat $input_phage_cluster_file | grep -c "${line_info}")
		echo -e "${phage_cluter_hit_num}\t\c" >> ${input_blast_file_name}_virus_tem.tsv

		## get the hightes score of phage if it as >1 hits
		if [ $phage_cluter_hit_num -gt 1 ]
		then
			echo -e ">${line_gene_name}" >> ${input_blast_file_name}_virus_tem_hit_gt2.tsv
			cat $input_phage_cluster_file | grep "${line_info}" >> ${input_blast_file_name}_virus_tem_hit_gt2.tsv
			gene_cat_0_num=$(cat ${input_blast_file_name}_virus_tem_hit_gt2.tsv | grep -c "|0|")
			gene_cat_1_num=$(cat ${input_blast_file_name}_virus_tem_hit_gt2.tsv | grep -c "|1|")
			gene_cat_2_num=$(cat ${input_blast_file_name}_virus_tem_hit_gt2.tsv | grep -c "|2|")
			gene_cat_3_num=$(cat ${input_blast_file_name}_virus_tem_hit_gt2.tsv | grep -c "|3|")
			gene_cat_4_num=$(cat ${input_blast_file_name}_virus_tem_hit_gt2.tsv | grep -c "|4|")
			if [ $gene_cat_0_num -ge 1 ]; then
				cat ${input_blast_file_name}_virus_tem_hit_gt2.tsv | grep "|0|" | head -1 >> ${input_blast_file_name}_virus_tem.tsv
			else
				if [ $gene_cat_3_num -gt 1 ]; then
					cat ${input_blast_file_name}_virus_tem_hit_gt2.tsv | grep "|3|" | head -1 >> ${input_blast_file_name}_virus_tem.tsv
				else
					if [ $gene_cat_1_num -gt 1 ]; then
						cat ${input_blast_file_name}_virus_tem_hit_gt2.tsv | grep "|1|" | head -1 >> ${input_blast_file_name}_virus_tem.tsv
					else
						if [ $gene_cat_2_num -gt 1 ]; then
							cat ${input_blast_file_name}_virus_tem_hit_gt2.tsv | grep "|2|" | head -1 >> ${input_blast_file_name}_virus_tem.tsv
						else 
							cat ${input_blast_file_name}_virus_tem_hit_gt2.tsv | head -1 >> ${input_blast_file_name}_virus_tem.tsv
						fi
					fi
				fi
			fi
			

		## if there is only 1 or 0 hit
		elif [ $phage_cluter_hit_num -eq 1 ]
		then
			cat $input_phage_cluster_file | grep "${line_info}" >> ${input_blast_file_name}_virus_tem.tsv
		else # i.e., $phage_cluster_hit_num=0
			echo -e "Phage_cluster_unclustered|1|unknown" >> ${input_blast_file_name}_virus_tem.tsv
		fi

	else
		echo -e "-\t-" >> ${input_blast_file_name}_virus_tem.tsv
	fi
done

paste  ${input_blast_file_name}_virus.tsv ${input_blast_file_name}_virus_tem.tsv > ${input_blast_file_name}_virus_1.tsv
mv ${input_blast_file_name}_virus_1.tsv ${input_blast_file_name}_virus.tsv
rm ${input_blast_file_name}_virus_tem.tsv



## add halmark or not information
echo -e "Gene type\tGene color" > ${input_blast_file_name}_virus_tem.tsv
cat ${input_blast_file_name}_virus.tsv | sed "1"d | cut -f18 | cut -f2 -d "|" | while read line
do
	if [ $line == "-" ]; then
		echo -e "Unaffiliated gene\t/color=192 192 192" >> ${input_blast_file_name}_virus_tem.tsv
	else
		if [ $line == "0" ] || [ $line == "3" ]; then
			echo -e "Hallmark gene\t/color=0 0 255" >> ${input_blast_file_name}_virus_tem.tsv
		else
			echo -e "Phage gene\t/color=255 128 0" >> ${input_blast_file_name}_virus_tem.tsv
		fi
	fi
done

paste  ${input_blast_file_name}_virus.tsv ${input_blast_file_name}_virus_tem.tsv > ${input_blast_file_name}_virus_1.tsv
mv ${input_blast_file_name}_virus_1.tsv ${input_blast_file_name}_virus.tsv
rm ${input_blast_file_name}_virus_tem.tsv


## check if some genes are missing
cat ${input_blast_file_name}_virus.tsv | sed "1"d | cut -f1 > ${input_blast_file_name}_gene_name_blast.txt
cat $path_input | grep '^>' | sed "s/^>//g" > ${input_blast_file_name}_gene_name_pro.txt
comm -13 ${input_blast_file_name}_gene_name_blast.txt ${input_blast_file_name}_gene_name_pro.txt > ${input_blast_file_name}_gene_name_missing.txt

# total gene number
total_gene_num=$(grep -c '^>' $path_input )

line_empty="no hit\tno hit\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\t-\tUnaffiliated gene\t/color=192 192 192"
grep -n -w -f ${input_blast_file_name}_gene_name_missing.txt ${input_blast_file_name}_gene_name_pro.txt | while read line;
do
	gene_name=$(echo $line | cut -f2 -d ":")
	gene_missing_num=$(echo $line | cut -f1 -d ":")
	if [ $gene_missing_num -eq $total_gene_num ]; then
		echo "${gene_name}\t${line_empty}" >> ${input_blast_file_name}_virus.tsv
	else
	    gene_missing_line_num=$((gene_missing_num + 1))
	    sed -i "${gene_missing_line_num}i${gene_name}\t${line_empty}" ${input_blast_file_name}_virus.tsv
    fi
done

rm ${input_blast_file_name}_gene_name_blast.txt ${input_blast_file_name}_gene_name_pro.txt 
# rm ${input_blast_file_name}_gene_name_missing.txt 

# double check
total_blast_num=$(cat ${input_blast_file_name}_virus.tsv | sed "1"d | wc -l)
if [ $total_blast_num -ne $total_gene_num ]; then
	echo "Warming: blasted gene number is not equal to total gene number"
fi


if [ -z "$input_genbank" ]; then
	echo -e "Job done!!"
  echo -e "    -g is not provided"
  echo -e "    Only annotating genes, no modification of genbank file\n"
  echo -e "\nOne output: \n   1) *_blast_output_11_fmt6_firstHit_virus.tsv: it contains gene information by comparing to virsorter v1 database\n"
  exit 0

else
  echo -e "Now modifying genbank file..."

	## modify the genbank file to add the color information
	cp $input_genbank ${input_genbank_name}_new.gbk
	line_count=1
	cat $input_genbank | grep "^     CDS" | while read line
	do 
		((line_count++))
		line_or=$(echo $line | cut -f2 -d " ")
		line_tem=$(cat ${input_blast_file_name}_virus.tsv | sed -n ${line_count}p | cut -f 20)
		line_tem1='\'${line_tem}
		sed -i "s/     CDS             ${line_or}/     CDS             ${line_or}\n                     ${line_tem1}/g" ${input_genbank_name}_new.gbk
	done

	echo -e "Job done!!\n"
	echo -e "\nTwo outputs: \n   1) *_blast_output_11_fmt6_firstHit_virus.tsv: it contains gene information by comparing to virsorter v1 database\n   2) ${input_genbank_name}_new.gbk: it contains color information indicating 3 kind of genes inlcuding 'phage gene (orange, 255 128 0)', 
	'Hallmark gene (blue, 0 0 255)', and 'unclassified gene (grey, 192 192 192)'. It can be used as input of EasyFig to draw genome map\n"

fi
