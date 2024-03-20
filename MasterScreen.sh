#!/bin/bash 

#    This file originally comes from LEDE-CREST repository found at
#    https://github.com/nking1/LEDE-CREST
#    Changelog is provided in form of a commit.
#    Modifications were implemented by Oskar Klimas, ACK Cyfronet AGH, Kraków, Poland
#    The reasoning for these changes can be found in README.txt

#SBATCH --account=ACCT 
#SBATCH --ntasks=ScreenTasks 
#SBATCH -N 1 
#SBATCH --mem-per-cpu=ScreenMem 
#SBATCH --time=ScreenTime 
#SBATCH --mail-type=ALL 
#SBATCH --mail-user=EMAIL 
#SBATCH --array=1-ScreenCount
#SBATCH --output=basenameScreen.out

ml crest_module
#dos2unix AScreen/basename.xyz
LinesPerMol=$(echo 2+$(sed -n '1p' AScreen/basename.xyz) | bc -l)
DIR=$(sed -n "${SLURM_ARRAY_TASK_ID}p" screen.dir) 
cd $DIR 
echo Starting task $SLURM_ARRAY_TASK_ID in dir $DIR
rm xtb.trj
export OMP_STACKSIZE=Stacksize
for n in {1..4}
 do echo -e "\n" >> ../${DIR::1}$n/xtb.trj
 Lines=$(wc -l ../${DIR::1}$n/xtb.trj | awk '{print $1}')
 Rem=$(echo "($Lines % $LinesPerMol)" | bc)
 head -n -$Rem ../${DIR::1}$n/xtb.trj >> xtb.trj
done
crest -screen xtb.trj -T 28 -g Solvent --chrg CHARGE > basename.out
