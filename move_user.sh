#!/bin/bash

# copy data from Windows 7 (and XP?) machine to locally created accounts
# by Adam Gerstein
# v1.0

# pseudo code:
# select user account (drag into terminal window)
# create local account
# 	logic to create locally vs AD depending on where I am
# copy data from Win7 drive to locally created user account
# move data from "My *foldername*" to relevant folder
# chmod directory for ownership
# log it all

# logs everything we do to logfile.txt
exec > >(tee logfile.txt)
# http://stackoverflow.com/questions/3173131/redirect-copy-of-stdout-to-log-file-from-within-bash-script-itself


# begin
clear
scpname=`basename $0`

# Check to make sure we are root
if [ `id -u` != "0" ]
then
   echo "$scpname must be run as root"
   exit 1
fi

#If $1 is empty ask user for input
if [ "$1" == "" ]; then
	echo "Please drag in the folder you want to copy and press Enter: "
	while [ -z "$DIR_SOURCE" ]; do
	read DIR_SOURCE
	done
else
	DIR_SOURCE="$1"
fi

#Check it is a folder that has been draged on
if [ ! -d "$DIR_SOURCE" ]; then
	echo ""$DIR_SOURCE" is not a folder..."
	exit 1
fi	

#Remove Escapes from $DIR_SOURCE
DIR_SOURCE=`echo $DIR_SOURCE | sed 's/\\\//g'`
echo "dir_source: " $DIR_SOURCE

# chop up dir source and extract the username
USER_NAME=$(basename $DIR_SOURCE)
echo "user_name: " $USER_NAME

# confirm the username is what we'll be using for the local/network account
if [ "$CONFIRM_USER" == "" ]; then
	echo "Is the username \"$USER_NAME\"? (Y/N)"
	while [ -z "$CONFIRM_USER" ]; do
	read CONFIRM_USER
	done
else
	CONFIRM_USER="N"
fi
echo "$CONFIRM_USER"

# create the user directory
# mkdir /Users/$destinationUser

# ditto the User Template into the user folder
# ditto /System/Library/User\ Template/English.lproj /Users/$destinationUser

#????
# chown -R <local admin ID to copy data in> /Users/$destinationUser

# copy the user data into the home
# ditto $DIR_SOURCE /Users/$destinationUser

# change ownership so that the local/network account has ownership
# chown -R $destinationUser /Users/$destinationUser
