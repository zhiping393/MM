#PBS -l walltime=24:00:00
#PBS -l nodes=1:ppn=10
#PBS -N CheckM
#PBS -m ae
#PBS -S /bin/bash
#PBS -j oe
#PBS -A PAS1117


## working directory
workDir=/fs/project/PAS1117/VranaLake/10_re-analysis/04_MAGs/08_checkM/01_all_99
cd $workDir

## genome directory
genomeDir=/fs/project/PAS1117/VranaLake/10_re-analysis/04_MAGs/03_MAGs_all_99

## genome file extension
genomeEx=fa

## thread number
threadnumber=10

## tool
module use /fs/project/PAS1117/zhiping/software/1_modules/modulefiles
module load anaconda3.6
source activate checkM

## run checkM to check genome quality
checkm lineage_wf -t $threadnumber -x $genomeEx $genomeDir ${workDir}/02_checkm_out


#### below can be removed
## helpful information to log file
sh /users/PAS1117/osu7810/functions/func_add_efficiency_logFile.sh

