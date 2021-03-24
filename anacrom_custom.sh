#!/bin/bash

#TODO: add logging

# parse command line arg(s)
#from https://stackoverflow.com/a/33826763/5409497
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -s|--shutdown) shutdown=true; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

## actual anacron functionality
timestamp_now=$(date '+%s')

# get the timestamp of the lastrun_* file or create it if it does not exist (no backup has been run so far)
# arg #1: daily, monthly, weekly
check_file_timestamp () {
    # return timestamp of last file change
    if [[ -f lastrun.$1 ]]; then {
        echo $(stat -c%Y lastrun.$1)
    } else {
        echo 0
    } fi
}

# compare the file timestamp to now and check against a threshold and return if a backup must be done
# args #1: daily, weekly, monthly
check_backup_age () {
    timestamp_difference=$((timestamp_now - timestamp_$1))
    if [[ $timestamp_difference -gt $2 ]]; then {
        echo true
    } else {
        echo false
    } fi
}

# run rsnapshot and update the lastrun_* file
# args #1: daily, weekly, monthly
do_backup () {
    /usr/bin/rsnapshot $1

    if [[ -f lastrun.$1 ]]; then {
        rm lastrun.$1
    } fi
    /usr/bin/touch "lastrun.$1"
}

# do daily backup if needed
timestamp_daily=$(check_file_timestamp daily)
echo "Last daily backup: $(date -d @$timestamp_daily '+%Y-%m-%d %H:%M:%S')"
if [[ $(check_backup_age daily 10) == true ]]; then {
    do_backup daily
} else {
    echo "Do not need to run daily backup"
} fi

# do weekly backup if needed
timestamp_weekly=$(check_file_timestamp weekly)
echo "Last daily backup: $(date -d @$timestamp_weekly '+%Y-%m-%d %H:%M:%S')"
if [[ $(check_backup_age weekly 604000) == true ]]; then {
    do_backup weekly
} else {
    echo "Do not need to run weekly backup"
} fi

# do monthly backup if needed
timestamp_monthly=$(check_file_timestamp monthly)
echo "Last daily backup: $(date -d @$timestamp_monthly '+%Y-%m-%d %H:%M:%S')"
if [[ $(check_backup_age monthly 16934000) == true ]]; then {
    do_backup monthly
} else {
    echo "Do not need to run monthly backup"
} fi

## will shutdown the system after backup
if [ "$shutdown" = true ]; then
    echo "Would shutdown system"
    #/sbin/shutdown
fi