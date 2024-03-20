#!/bin/bash

#    SLURM-CHECK - a tool to extract the status and remaining time in
#    queue/running using scontrol.
#    Copyright (C) 2024 ACK Cyfronet AGH, Kraków, Poland
#    Author: Oskar Klimas
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <https://www.gnu.org/licenses/>.

# LEGEND of statuses
# 0 -> Error of this script.
# 1 -> Unknown Time of start. The time hasn't been assigned yet, so 
# pending.
# 2 -> Pending.
# 3 -> Running.
# 4 -> Completed.
# 5 -> Invalid ID, which means Completed. scontrol removes the job from
# its history after a short moment after completion.

is_valid_datetime() {
    # Used to check for Unknown Time of start
    date -d "$1" "+%Y-%m-%d %H:%M:%S" >/dev/null 2>&1
}

calculate_seconds_between_dates() {
    # Usage: calculate_seconds_between_dates "date1" "date2"
    # Example: calculate_seconds_between_dates "2024-03-18T12:00:00" "2024-03-19T12:00:00"
    # The number of seconds can be used to determine sleep time in another script
    local date1_sed=$(echo "$1" | sed 's/T/ /')
    local date2_sed=$(echo "$2" | sed 's/T/ /')
    local date1=$(date -d "$date1_sed" +"%s")
    local date2=$(date -d "$date2_sed" +"%s")
    local seconds=$((date2 - date1))
    echo "$seconds"
}

# Check scontrol for job information
read_job=$(scontrol show job $1 2>&1)

# Check for Invalid job id
[[ "$read_job" == *"error"*"nvalid job id"* ]] && { echo "5 Completed left 0 s" ; exit 0 ; }

# Gather dates
start_awk=$(echo "$read_job" | grep "StartTime" | awk '{print $1}')
[[ -z "$start_awk" ]] && { echo "0" ; exit 0 ; } # Sanity check
start=${start_awk##*=}
end_awk=$(echo "$read_job" | grep "EndTime" | awk '{print $2}')
[[ -z "$end_awk" ]] && { echo "0" ; exit 0 ; } # Sanity check
end=${end_awk##*=}
current=$(date +"%Y-%m-%dT%H:%M:%S")


# Check if start time is a valid date-time
if ! is_valid_datetime "$start"; then
    echo "1 Pending   for  Unknown s more" ; exit 0
fi

# Check if Completed
if [[   "$end" < "$current" ]] ; then
    echo "4 Completed left 0 s"
    exit 0
fi

# Check if Running
if [[ "$start" < "$current" ]] ; then
    seconds=$(calculate_seconds_between_dates "$current" "$end")
    echo "3 Running   for  $seconds s more"
    exit 0
fi

# Otherwise Pending
seconds=$(calculate_seconds_between_dates "$current" "$start")
echo "2 Pending   for  $seconds s more" ; exit 0
