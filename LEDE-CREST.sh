#!/bin/bash

#    This file originally comes from LEDE-CREST repository found at
#    https://github.com/nking1/LEDE-CREST
#    Changelog is provided in form of a commit.
#    Modifications were implemented by Oskar Klimas, ACK Cyfronet AGH, Kraków, Poland
#    The reasoning for these changes can be found in README.txt

slurm_sleeper() {
# Copyright for this function can be found in slurm_sleeper_function_copy.txt
local status_awk=$($parentdir/SLURM-CHECK.sh "$1")
local status=$(echo "$status_awk" | awk '{print $1}')
local seconds=$(echo "$status_awk" | awk '{print $4}')
! [[ $status =~ ^[0-9]+$ ]] && { echo "ERROR status is not a number. Check SLURM_CHECK.sh for possible cause." ; exit 1 ; } # Sanity check
while [[ "$status" -lt 4 ]]; do
    case "$status" in
        0)
            echo "Error of the SLURM_CHECK.sh script."
            exit 1
            ;;
        1)
            # Unknown Time of start => check again in a minute
            sleep_s=60
            ;;
        2)
            # Pending => check infrequently
            sleep_s=$(( seconds > 900 ? 300 : seconds / 3 ))
            ;;
        3)
            # Running => check frequently, when job is close to time
            # limit
            sleep_s=$(( seconds > 3000 ? 300 : seconds / 10 ))
            ;;
    esac
    [[ "$sleep_s" -lt 5 ]] && sleep_s=5 # this condition is necessary
    # do not lower the minimal time below 5 s without the approval of
    # your cluster admins
    sleep "$sleep_s"s
    status_awk=$($parentdir/SLURM-CHECK.sh "$1")
     status=$(echo "$status_awk" | awk '{print $1}')
    seconds=$(echo "$status_awk" | awk '{print $4}')
done
}

basename=
account=
email=
crest_module='StdEnv/2020 crest/2.12'
xtb_module='StdEnv/2020 xtb/6.5.0'
Solvent=
CHARGE=0
KPush1=0.05
KPush2=0.015
Alp1=1.3
Alp2=3.1
SimLength=30
MTDTasks=4
MTDMem=512M
MTDTime=0-3
Stacksize=2G
ScreenTasks=28
ScreenMem=256M
ScreenTime=0-12
MaxConfCount=12
PassQuotient=0.5
MinRMSD=1.0
MaxCycles=10

# Determine the path to LEDE-CREST top directory
parentdir=$(pwd -P)

# Set up scripts

sed "s/basename/$basename/g; s/ACCT/$account/g; s/EMAIL/$email/g; s/Solvent/$Solvent/g; s/MaxCycles/$MaxCycles/g; s|parentdir|$parentdir|g" MasterNextCycle.sh > TemplateNextCycle.sh
sed "s/basename/$basename/g; s/ACCT/$account/g; s/EMAIL/$email/g; s/MTDTasks/$MTDTasks/g; s/MTDMem/$MTDMem/g; s/MTDTime/$MTDTime/g; s/Stacksize/$Stacksize/g; s/Solvent/$Solvent/g; s/CHARGE/$CHARGE/g; s|parentdir|$parentdir|g; s|xtb_module|$xtb_module|g" MasterMTD.sh > TemplateMTD.sh
sed "s/basename/$basename/g; s/ACCT/$account/g; s/EMAIL/$email/g; s/Solvent/$Solvent/g; s/Stacksize/$Stacksize/g; s/ScreenTasks/$ScreenTasks/g; s/ScreenMem/$ScreenMem/g; s/ScreenTime/$ScreenTime/g; s/CHARGE/$CHARGE/g; s|parentdir|$parentdir|g; s|crest_module|$crest_module|g" MasterScreen.sh > TemplateScreen.sh
sed "s/basename/$basename/g; s/ACCT/$account/g; s/EMAIL/$email/g; s/MaxConfCount/$MaxConfCount/g; s/PassQuotient/$PassQuotient/g; s/MinRMSD/$MinRMSD/g; s|parentdir|$parentdir|g; s|crest_module|$crest_module|g" MasterProcess.sh > TemplateProcess.sh
sed "s/basename/$basename/g; s/ACCT/$account/g; s/EMAIL/$email/g; s/Stacksize/$Stacksize/g; s/Solvent/$Solvent/g; s/CHARGE/$CHARGE/g; s|parentdir|$parentdir|g; s|crest_module|$crest_module|g" MasterCREGEN.sh > CREGEN.sh

# Make initial Cycle directory

mkdir Cycle1
cd Cycle1

# Establish cycle count

echo 1 > cyclecount.txt

# Copy in Scripts

sed "s/MTDCount/4/g" $parentdir/TemplateMTD.sh > MTD.sh
sed "s/ScreenCount/1/g" $parentdir/TemplateScreen.sh > Screen.sh
cp $parentdir/TemplateProcess.sh Process.sh
cp $parentdir/TemplateNextCycle.sh NextCycle.sh

# Set up MTD and Screen directories and directory lists

for n in {1..4}
 do mkdir A$n
 echo A$n >> mtd.dir
 done
mkdir AScreen
echo AScreen > screen.dir

# Set up MTD input files

for d in ?1/
 do echo -e '$metadyn \nsave=100' > $d/$basename.inp
    echo "kpush=$KPush1" >> $d/$basename.inp
    echo "alp=$Alp1" >> $d/$basename.inp
    echo -e '$end \n$md' >> $d/$basename.inp
    echo "time=$SimLength" >> $d/$basename.inp
    echo -e 'step=1 \ntemp=298 \n$end \n$wall \npotential=logfermi \nsphere: auto,all \n$end' >> $d/$basename.inp
 done

for d in ?2/
 do echo -e '$metadyn \nsave=100' > $d/$basename.inp
    echo "kpush=$KPush2" >> $d/$basename.inp
    echo "alp=$Alp1" >> $d/$basename.inp
    echo -e '$end \n$md' >> $d/$basename.inp
    echo "time=$SimLength" >> $d/$basename.inp
    echo -e 'step=1 \ntemp=298 \n$end \n$wall \npotential=logfermi \nsphere: auto,all \n$end' >> $d/$basename.inp
 done

for d in ?3/
 do echo -e '$metadyn \nsave=100' > $d/$basename.inp
    echo "kpush=$KPush1" >> $d/$basename.inp
    echo "alp=$Alp2" >> $d/$basename.inp
    echo -e '$end \n$md' >> $d/$basename.inp
    echo "time=$SimLength" >> $d/$basename.inp
    echo -e 'step=1 \ntemp=298 \n$end \n$wall \npotential=logfermi \nsphere: auto,all \n$end' >> $d/$basename.inp
 done

for d in ?4/
 do echo -e '$metadyn \nsave=100' > $d/$basename.inp
    echo "kpush=$KPush2" >> $d/$basename.inp
    echo "alp=$Alp2" >> $d/$basename.inp
    echo -e '$end \n$md' >> $d/$basename.inp
    echo "time=$SimLength" >> $d/$basename.inp
    echo -e 'step=1 \ntemp=298 \n$end \n$wall \npotential=logfermi \nsphere: auto,all \n$end' >> $d/$basename.inp
 done

# Copy in starting structure
for d in A*/
 do cp $parentdir/$basename.xyz "$d"
done

# Submit scripts
for step in MTD Screen Process ; do
    jobid_awk=$(sbatch --job-name=$step-$basename $step.sh 2>&1)
    jobid=$(echo $jobid_awk | awk '{print $4}')
    slurm_sleeper "$jobid"
done

# Run Next Cycle
chmod u+x NextCycle.sh
./NextCycle.sh 2>&1
