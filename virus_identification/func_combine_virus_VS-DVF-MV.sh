#!/bin/bash

##*********************************************************************************************************************************
# This script combines sequences of viral contigs from DeepVirfinder, MARVEL, and VIRSorter based on the standards in             *
# Sullivan Lab.                                                                                                                   *
#                                                                                                                                 *
# This script could be used in any folder (the output directory)                                                                  *
# Usage: Usage: bash combine-virus-VirSF.sh DVF-outputfile.txt MARVEL_log_file.log Dir/to/Virsorter/output assembled_contigs.fasta  *
#                                                                                                                                 *
# Contact: zhongzhipingmail@163.com                                                                                               *
#**********************************************************************************************************************************

## help message
usage() {
echo -e "
      Combine the viral contigs predicted by 3 tools: DeepVirfinder, MARVEL, and Virsorter
      Usage: bash combine-virus-VirSF.sh -d DVF-outputfile.txt -m MARVEL_log_file.log -v Dir/to/Virsorter/output -i assembled_contigs.fasta
      There are 4 input files\n

Parameters:
-d      input file 1 --- Deep virfinder output. e.g., gt1bp_dvfpred.txt
-m      input file 2 --- MARVEL output log file. e.g., log-file_MARVEL_10_GS3.48.6.B_0.5kb.o858052
-v      input file 3 --- VirSorter output folder. e.g., output_16_GP2.134.2.B_0.5kb_virsorter
-i      input file 4 --- Original contigs used for viral prediction. e.g., contigs.fasta (of Spades output)
"
}

##### --help
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

echo -e "This script was used to combine the viral contigs predicted by 3 tools: DeepVirfinder, MARVEL, and Virsorter" >> ReadMe.txt
echo -e "      Usage: bash combine-virus-VirSF.sh DVF-outputfile.txt MARVEL_log_file.log Dir/to/Virsorter/output assembled_contigs.fasta\n             There are 4 input files\n" >> ReadMe.txt


## arguments and variables (i, d, v, m)
input_DVF=/users/PAS1117/osu7810/database/combine_virus/output_DVF/empty-sample.fasta_gt1bp_dvfpred.txt
input_MV=/users/PAS1117/osu7810/database/combine_virus/log-file_MARVEL_empty-file
input_VS=/users/PAS1117/osu7810/database/combine_virus/output_virsorter
while getopts "d:m:v:i:" opt
do
  case $opt in
    d)
        input_DVF=$OPTARG;;
    m)
        input_MV=$OPTARG;;
    v)  
        input_VS=$OPTARG;;
    i)
        input_cont=$OPTARG;;
    \?)
        echo "invalid argument"
        exit 1;;
  esac
done

##### Files
# input_DVF=$1  #output file of DVF - deep virfinder
# input_MV=$2   #The output .log file of MARVEL
# input_VS=$3   #output directory of Virsorter
# input_cont=$4 #all assembled contings file, which were the input of DVF and VS; e.g., contigs_1.5kb.fasta; can also use contigs.fasta from the spades output, if it was original file for viral prediction

##### names
DVF_name=${input_DVF##*/}
MV_name=${input_MV##*/}
cont_name=${input_cont##*/} #.fasta
cont_name1=${cont_name%.*}  #delete the .fasta
cont_name_oneline=$cont_name1"_oneline.fasta"
cont_name_end=$cont_name1"_end.fasta" ## add marker "_end" to the end of each sequence name

## check if there is this folder: Predicted_viral_sequences
VS_output=$(ls $input_VS | grep -c -w 'Predicted_viral_sequences')
if [ $VS_output -eq 0 ]; then
      echo -e "  WARMING: VIRSorter output is empty, please check it and try it again\n"
      exit 1
fi

##### get the input files to the base folder
cp $input_DVF .
cp $input_MV .
cp -r $input_VS/Predicted_viral_sequences/ .
cp $input_cont .

##### make each sequence to one line in the contigs (contigs_oneline.fasta); Add marker "_end" to each sequence name (this will be convinience for picking sequences)
awk '/^>/ {printf("\n%s\n",$0);next; } { printf("%s",$0);}  END {printf("\n");}' < $cont_name | sed '/^$/d; /--/d' > $cont_name_oneline
sed '/>/s/$/_end/' $cont_name_oneline > $cont_name_end

##### change the names of Virsorter output: change some under scores back to dots - be consistent with MARVEL and DVF outputs
number_dot=$(grep '^>' $cont_name_oneline | grep -c '\.')
if [ $number_dot -eq 0 ]; then
      echo -e "No need to change underscore to dot from Virsorter output"
else 
      echo -e "      Changing the names of Virsorter output: change some under scores back to dots - be consistent with MARVEL and DVF outputs\n"
      grep '^>' $cont_name_oneline | sed 's/>//g' | sed 's/\./_/g' > $cont_name1"_us.txt"
      grep '^>' $cont_name_oneline | sed 's/>//g' > $cont_name1"_dot.txt"
      paste $cont_name1"_us.txt" $cont_name1"_dot.txt" > $cont_name1"_us-dot.txt"
      cd Predicted_viral_sequences/
      cat VIRSorter_cat-1.fasta VIRSorter_cat-2.fasta VIRSorter_cat-3.fasta VIRSorter_prophages_cat-4.fasta VIRSorter_prophages_cat-5.fasta VIRSorter_prophages_cat-6.fasta | grep '^>' | sed 's/>VIRSorter_//g; s/-circular/|-circular/g; s/-cat/|-cat/g; s/_gene/|_gene/g' | cut -f1 -d "|" | sort -g > ../VIRSorter_cat-1-2-3-4-5-6_names.txt
      cd ../
      cat $cont_name1"_us-dot.txt" | grep -f VIRSorter_cat-1-2-3-4-5-6_names.txt | sed '/^$/d; /--/d' > VIRSorter_cat-1-2-3-4-5-6_us-dot.txt
      cut -f1 VIRSorter_cat-1-2-3-4-5-6_us-dot.txt > VIRSorter_cat-1-2-3-4-5-6_us.txt
      cut -f2 VIRSorter_cat-1-2-3-4-5-6_us-dot.txt > VIRSorter_cat-1-2-3-4-5-6_dot.txt
      cont_number=$(cat VIRSorter_cat-1-2-3-4-5-6_dot.txt | wc -l)
      n=$(seq 1 $cont_number)
      for m in $n; do
          name_us=$(sed -n $m"p" VIRSorter_cat-1-2-3-4-5-6_us.txt)
          name_dot=$(sed -n $m"p" VIRSorter_cat-1-2-3-4-5-6_dot.txt)
          sed -i "s/$name_us/$name_dot/g" Predicted_viral_sequences/VIRSorter_cat-1.fasta
          sed -i "s/$name_us/$name_dot/g" Predicted_viral_sequences/VIRSorter_cat-2.fasta
          sed -i "s/$name_us/$name_dot/g" Predicted_viral_sequences/VIRSorter_cat-3.fasta
          sed -i "s/$name_us/$name_dot/g" Predicted_viral_sequences/VIRSorter_prophages_cat-4.fasta
          sed -i "s/$name_us/$name_dot/g" Predicted_viral_sequences/VIRSorter_prophages_cat-5.fasta
          sed -i "s/$name_us/$name_dot/g" Predicted_viral_sequences/VIRSorter_prophages_cat-6.fasta
      done
echo -e "      Names change done\n"
fi


############### start to extract viral sequences from here
##### 1) virsorter cat 1 & 2 - get sequence names
cd Predicted_viral_sequences/
cat VIRSorter_cat-1.fasta VIRSorter_cat-2.fasta VIRSorter_prophages_cat-4.fasta VIRSorter_prophages_cat-5.fasta > VIRSorter_cat-1-2-4-5.fasta ; cp VIRSorter_cat-1-2-4-5.fasta ../
cat VIRSorter_cat-1.fasta VIRSorter_cat-2.fasta > VIRSorter_cat-1-2.fasta
grep '^>' VIRSorter_cat-1-2.fasta > VIRSorter_cat-1-2_names.txt
sed -i 's/>VIRSorter_//g; s/-circular//g; s/-cat/|-cat/g' VIRSorter_cat-1-2_names.txt
cut -f1 -d "|" VIRSorter_cat-1-2_names.txt | sed 's/$/_end/' > VIRSorter_cat-1-2_names_1.txt
cp VIRSorter_cat-1-2_names_1.txt ../; cd ../

##### 2) Deep VirFinder (scores >=0.9 & p <=0.05) - get sequence names
awk -F"\t" '$4<=0.05' $DVF_name > DVF_005.txt # contigs with p value <=0.05
awk -F"\t" '$3>=0.9' DVF_005.txt > DVF_005090.txt # contigs with score >0.9 -- high quality for virus
sed '/name/d' DVF_005090.txt > DVF_005090_notitle.txt
cut -f1 DVF_005090_notitle.txt > DVF_005090_names.txt # column was devided by "tab"
sed -i 's/$/_end/' DVF_005090_names.txt # add marker "_end" to the end of each sequence name

##### 3) MARVEL (probability >=90%) - get sequence names
grep '%' $MV_name | grep '\->' | grep '\*\*\*' > MARVEL_virusName_0.txt # get the viruses from the .log file
cut -d " " -f 2,5 MARVEL_virusName_0.txt > MARVEL_virusName_1.txt # get the 2 columns with viral names and probability percentage
awk -F " " '$2>=90' MARVEL_virusName_1.txt > MARVEL_90.txt # viral contigs >90% probability -- high quality
cut -d " " -f1 MARVEL_90.txt > MARVEL_90_names.txt # get the first column, only contain viral names -- high quality 90%
sed -i 's/$/_end/' MARVEL_90_names.txt # add marker "_end" to the end of each sequence name

##### 4) Deep VirFinder (0.7<= scores <0.9 & p <=0.05) & MARVEL (70%<= probability <90%)
## Deep VF
awk -F"\t" '$3<0.9' DVF_005.txt | awk -F"\t" '$3>=0.7' > DVF_005070090.txt # viral contigs with 0.7-0.9 scores
sed '/name/d' DVF_005070090.txt > DVF_005070090_notitle.txt
cut -f1 DVF_005070090_notitle.txt > DVF_005070090_names.txt # column was devided by "tab"
sed -i 's/$/_end/' DVF_005070090_names.txt # add marker "_end" to the end of each sequence name
## MARVEL
awk -F " " '$2<90' MARVEL_virusName_1.txt | awk -F " " '$2>=70' > MARVEL_70-90.txt # viral contigs 70-90% probability
cut -d " " -f1 MARVEL_70-90.txt > MARVEL_70-90_names.txt # get the first column, only contain viral names -- high quality 90%
sed -i 's/$/_end/' MARVEL_70-90_names.txt # add marker "_end" to the end of each sequence name
## get overlap
cat DVF_005070090_names.txt MARVEL_70-90_names.txt | sort -g | uniq -d > DVF-MARVEL_medium_names.txt

##### 5) combine (1-4) - get viral sequence names and sequences - virus detected in at least one of 1-4
cat VIRSorter_cat-1-2_names_1.txt DVF_005090_names.txt MARVEL_90_names.txt DVF-MARVEL_medium_names.txt | sort -g | uniq > DVF-MV-VS12_names.txt
/fs/project/PAS1117/zhiping/software/bbmap_38.43/filterbyname.sh in=$cont_name_end names=DVF-MV-VS12_names.txt  out=DVF-MV-VS12.fasta include=t substring=name
sed -i '/>/s/_end$//' DVF-MV-VS12.fasta

##### 6) virsorter cat 4 & 5 - get sequence names - This one will extract partial sequence (prophage sequences) from contigs, so they were extracted individually. 
cd Predicted_viral_sequences/
cat VIRSorter_prophages_cat-4.fasta VIRSorter_prophages_cat-5.fasta > VIRSorter_cat-4-5.fasta
grep '^>' VIRSorter_cat-4-5.fasta > VIRSorter_cat-4-5_names.txt
sed -i 's/>VIRSorter_//g; s/_gene/|_gene/g; s/-circular/|-circular/g' VIRSorter_cat-4-5_names.txt
cut -f1 -d "|" VIRSorter_cat-4-5_names.txt | sed 's/$/_end/' > VIRSorter_cat-4-5_names_1.txt
sort -g VIRSorter_cat-4-5_names_1.txt | uniq > VIRSorter_cat-4-5_names_2.txt # sometimes, it detects two prophage in one contig
## virus only detected as VS4-5, but not by others in 5); Assume: they are not prophages if also detected in 5), so we may not find prophage although VS detected prophages
comm -23 VIRSorter_cat-4-5_names_2.txt ../DVF-MV-VS12_names.txt > VIRSorter_cat-4-5_names_3.txt
sed 's/_end$/_/' VIRSorter_cat-4-5_names_3.txt > VIRSorter_cat-4-5_names_4.txt
sed 's/_end$/-/' VIRSorter_cat-4-5_names_3.txt >> VIRSorter_cat-4-5_names_4.txt
/fs/project/PAS1117/zhiping/software/bbmap_38.43/filterbyname.sh in=VIRSorter_cat-4-5.fasta names=VIRSorter_cat-4-5_names_4.txt  out=VIRSorter_cat-4-5_prophage.fasta include=t substring=name
cd ../

#### 7) combine free viruses and prophages
cat DVF-MV-VS12.fasta Predicted_viral_sequences/VIRSorter_cat-4-5_prophage.fasta > virus_all_DVF-MV-VS.fasta

#### 8) circular viruses with length 1.5-5kb detected by VirSorter - used for ecology analysis 
awk '/^>/ {printf("\n%s\n",$0);next; } { printf("%s",$0);}  END {printf("\n");}' < VIRSorter_cat-1-2-4-5.fasta | sed '/^$/d; /--/d' | awk '{y= i++ % 2 ; L[y]=$0; if(y==1 && length(L[1])<5000) {printf("%s\n%s\n",L[0],L[1]);}}' | awk '{y= i++ % 2 ; L[y]=$0; if(y==1 && length(L[1])>=1500) {printf("%s\n%s\n",L[0],L[1]);}}' | grep 'circular' | sed 's/>VIRSorter_//g; s/-circular//g; s/-cat/|-cat/g' | cut -f1 -d "|" > virus_all_circular_1.5-5kb_names.txt
/fs/project/PAS1117/zhiping/software/bbmap_38.43/filterbyname.sh in=virus_all_DVF-MV-VS.fasta names=virus_all_circular_1.5-5kb_names.txt out=virus_all_circular_1.5-5kb.fasta include=t substring=name

#### 9) summarize numbers - quast
/fs/project/PAS1117/modules/quast/4.5/quast.py virus_all_DVF-MV-VS.fasta -m 10 --mgm -u --threads 28 -o Quast_virus_all_DVF-MV-VS > quiet.txt

#### 10) clean directory
## tempeorary files
mkdir tem_files 
shopt -s extglob 
mv !(tem_files) tem_files/
## input files
mkdir input_files; cd tem_files/; mv Predicted_viral_sequences/ $cont_name $DVF_name $MV_name ../input_files/
## 3 key files
cp -r virus_all_DVF-MV-VS.fasta Quast_virus_all_DVF-MV-VS virus_all_circular_1.5-5kb.fasta ReadMe.txt ../; cd ../
## .sh file
if [ $(ls | grep -c '\.sh') -eq 0 ]; then echo "No *.sh file here, that is fine; Just exit"; else cp *.sh ../script.sh; fi

echo -e "\n*****************************************************************************" >> ReadMe.txt
echo -e "The output contains 3 files:" >> ReadMe.txt
echo -e "    1) virus_all_DVF-MV-VS.fasta: all the viral contigs predicted by three tools MARVEL, DeepVirFinder, and VirSorter;\n    2) Quast_virus_all_DVF-MV-VS: this folder contains quast results of above viral contigs;\n    3) virus_all_circular_1.5-5kb.fasta: circular viral contigs with length 1.5-5kb predicted by VirSorter (This may be used for ecological analysis).\n" >> ReadMe.txt

echo -e "What viruses are in this output: virus_all_DVF-MV-VS.fasta?\n        It includes viruses detected by at least one of the following a-d): a) VirSorter: cat 1, 2, 4, or 5; b) MARVEL: probability >=90%; c) DeepVirFinder: scores >=0.9 & p-value <=0.05; d) (MARVEL: probability 70%-90%) & (DeepVirFinder: scores 0.7-0.9 & p-value <=0.05).\n        Prophages were extracted if they were only detected as cat 4 or 5 by VirSorter (not detected by MARVEL or DeepVirFinder).\n        **Caution**: For AMG analysis, you may need to remove viruses detected by d) to get \"high-quality\" viruses; But this is not required and will depends on yourself and the SOPs in your Lab\n        **Caution**: This script also works if you only have inputs from 2 of those 3 tools (e.g., you only have viruses predicted from virsorter and DVF, but not from marvel).\n" >> ReadMe.txt

echo -e "\nThanks for using this batch script to combine viral contigs predicted by 3 tools: DeepVirFinder, MARVEL, and VIRSorter" >> ReadMe.txt
echo -e "\n*****************************************************************************"
echo -e "Thanks for using this batch script to combine viral contigs predicted by 3 tools: DeepVirFinder, MARVEL, and VIRSorter\nTask done!! See ReadMe.txt for some helpful informaion on all output files\n"
