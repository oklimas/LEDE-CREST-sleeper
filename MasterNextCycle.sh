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

# Set up Cycle variables

CycleCount=$( cat cyclecount.txt)
NextCycle=$( echo "$CycleCount+1" | bc -l )
ConfCount=$( wc -l < allcandidatefilesSORTED.txt )

# Determine whether to terminate

Best=$( cat BestEnergy.txt)
Difference=1
if [[ $CycleCount -lt 3 ]] ; then 
 PrevPrevCycleCount=$( echo "$CycleCount-2" | bc -l )
 PrevBest=$( cat parentdir/Cycle$PrevPrevCycleCount/BestEnergy.txt )
 Difference=$( echo "$PrevBest - $Best" | bc -l )
fi

if [ $CycleCount -gt 2 ]; then
	if (( $(echo "$Difference < 0.000016" | bc -l) )); then
		cd parentdir
		sbatch CREGEN.sh
		exit
	fi
elif [ $CycleCount == MaxCycles ]; then
	echo "Not converged in MaxCycles cycles"
	exit
fi

# Create new cycle

if [ $CycleCount -lt 3 ] || (( $(echo "$Difference > 0.000016" | bc -l) )); then
	if [ $CycleCount != MaxCycles ]; then
		mkdir parentdir/Cycle$NextCycle
		cd parentdir/Cycle$NextCycle
		echo $NextCycle > cyclecount.txt

# Copy in Scripts

		sed "s/MTDCount/$( echo "$ConfCount*4" | bc -l)/g" parentdir/TemplateMTD.sh > MTD.sh
		sed "s/ScreenCount/$ConfCount/g" parentdir/TemplateScreen.sh > Screen.sh
		cp parentdir/TemplateProcess.sh Process.sh
		cp parentdir/TemplateNextCycle.sh NextCycle.sh

		rm *.dir 2>/dev/null

# Set up MTD and Screen directories and directory lists and copy in conformers

		if [ $ConfCount == 1 ]; then
			for n in {1..4}
				do mkdir A$n
				echo A$n >> mtd.dir
				done
			mkdir AScreen
			echo AScreen > screen.dir
  
			for d in A*
		  		do cp parentdir/Cycle$CycleCount/$( cat parentdir/Cycle$CycleCount/allcandidatefilesSORTED.txt ) $d/basename.xyz
				done
		
		else
			for val in $( eval echo "{1..$ConfCount}" )
				do
				Code=$( echo "$val+64" | bc -l )
				ConfLett=$( printf "\x$(printf %x $Code)" )
				for n in {1..4}
					do mkdir $ConfLett$n
					echo $ConfLett$n >> mtd.dir
					done
				mkdir "$ConfLett"Screen
				echo "$ConfLett"Screen >> screen.dir
				for d in "$ConfLett"*
					do cp parentdir/Cycle$CycleCount/$( sed -n "$val"p parentdir/Cycle$CycleCount/allcandidatefilesSORTED.txt ) $d/basename.xyz
					done
				done
  
		fi

		for d in ?1/
			do cp parentdir/Cycle1/A1/basename.inp $d
			done

		for d in ?2/
			do cp parentdir/Cycle1/A2/basename.inp $d
			done

		for d in ?3/
			do cp parentdir/Cycle1/A3/basename.inp $d
			done

		for d in ?4/
			do cp parentdir/Cycle1/A4/basename.inp $d
			done

		for step in MTD Screen Process ; do
		    jobid_awk=$(sbatch --job-name=$step-basename $step.sh 2>&1)
		    jobid=$(echo $jobid_awk | awk '{print $4}')
		    slurm_sleeper "$jobid"
		done
		chmod u+x NextCycle.sh
		./NextCycle.sh 2>&1
	fi
fi
