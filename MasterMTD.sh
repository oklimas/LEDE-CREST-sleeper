#!/bin/bash 

#    This file originally comes from LEDE-CREST repository found at
#    https://github.com/nking1/LEDE-CREST
#    Changelog is provided in form of a commit.
#    Modifications were implemented by Oskar Klimas, ACK Cyfronet AGH, Kraków, Poland
#    The reasoning for these changes can be found in README.txt

#SBATCH --account=ACCT
#SBATCH --ntasks=MTDTasks
#SBATCH -N 1 
#SBATCH --mem-per-cpu=MTDMem 
#SBATCH --time=MTDTime
#SBATCH --mail-type=ALL 
#SBATCH --mail-user=EMAIL
#SBATCH --array=1-MTDCount
#SBATCH --output=basename.out

ml xtb_module
export OMP_STACKSIZE=Stacksize
DIR=$(sed -n "${SLURM_ARRAY_TASK_ID}p" mtd.dir) 
cd $DIR 
echo "Starting task $SLURM_ARRAY_TASK_ID in dir $DIR" 
xtb basename.xyz --md --input basename.inp -P 4 -g Solvent --chrg CHARGE > basename.out
