#!/bin/bash

#    This file originally comes from LEDE-CREST repository found at
#    https://github.com/nking1/LEDE-CREST
#    Changelog is provided in form of a commit.
#    Modifications were implemented by Oskar Klimas, ACK Cyfronet AGH, Kraków, Poland
#    The reasoning for these changes can be found in README.txt

#SBATCH --account=ACCT
#SBATCH --mail-type=all
#SBATCH --mail-user=EMAIL
#SBATCH --ntasks=16
#SBATCH -N 1
#SBATCH --mem-per-cpu=2G
#SBATCH --time=1:0:0
#SBATCH --output=CREGEN.out

mkdir CREGEN
for ens in Cycle?/?Screen/crest_ensemble.xyz
 do cat $ens >> CREGEN/ensembles.xyz
done
cp Cycle1/A1/basename.xyz CREGEN
ml crest_module
export OMPSTACKSIZE=Stacksize
cd CREGEN
crest basename.xyz --cregen ensembles.xyz --notopo -g Solvent -T 16 --chrg CHARGE
cp crest_ensemble.xyz parentdir/final_ensemble.xyz
cp crest_best.xyz parentdir/LEDE-CREST_best.xyz
