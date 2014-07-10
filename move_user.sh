#!/bin/bash
# copy data from Windows 7 (and XP?) machine to locally created accounts
# Modified 2014-07-08
# Version 1.1
# by Adam Gerstein
# gersteina1@gmail.com
# https://github.com/agerstein/MoveUser


ACCOUNTPASSWORD="temppassword"
# you should change this to reflect your requirements - this is only for locally created accounts
# AD/OD accounts will get their password from the directory.

# pseudo code:
# select user account (drag into terminal window)
# create local account
# 	logic to create locally vs AD depending on where I am?
# copy data from Win7 drive to locally created user account
# move data from "My *foldername*" to relevant folder
# chmod directory for ownership
# log it all

# logs some of what we do to logfile.txt
exec > >(tee logfile.txt)
# inspiration from  http://stackoverflow.com/questions/3173131/redirect-copy-of-stdout-to-log-file-from-within-bash-script-itself

# begin
clear
scpname=$(basename "$0")

# Check to make sure we are root
if [ $(id -u) != "0" ]
then
   echo "$scpname must be run as root"
   exit 1
fi

#If $1 is empty ask user for input
if [ "$1" == "" ]; then
	echo "Please drag in the home directory you want to copy and press Enter: "
	while [ -z "$DIR_SOURCE" ]; do
	read DIR_SOURCE
	done
else
	DIR_SOURCE="$1"
fi

#Check it is a folder that has been draged on
if [ ! -d "$DIR_SOURCE" ]; then
	echo "$DIR_SOURCE is not a folder..."
	exit 1
fi	

#Remove Escapes from $DIR_SOURCE
DIR_SOURCE=$(echo "$DIR_SOURCE" | sed "s/\\\//g")
echo "dir_source: " "$DIR_SOURCE"

# chop up dir source and extract the username
USER_NAME=$(basename "$DIR_SOURCE")
echo "user_name: " "$USER_NAME"

# confirm the username is what we'll be using for the local/network account
if [ "$CONFIRM_USER" == "" ]; then
	echo "Is the username \"$USER_NAME\"? (Y/N)"
	while [ -z "$CONFIRM_USER" ]; do
		read CONFIRM_USER
		if [ "$CONFIRM_USER" == "Y" ]; then
			DIR_NAME=$USER_NAME
			echo "$DIR_NAME will be used."
		else [ "$CONFIRM_USER" == "N" ]; 
				echo "Please enter the username: "
				while [ -z "$NEW_DIR_NAME" ]; do
					read NEW_DIR_NAME
				DIR_NAME=$NEW_DIR_NAME
				echo "$DIR_NAME will be used."
				done
		fi
	done
else
	CONFIRM_USER="N"
	echo "Please enter the username: "
fi

# prompt for their full name - only used for local account creation
if [ "$REAL_NAME" == "" ]; then
	echo "Please enter users full name:"
	while [ -z "$REAL_NAME" ]; do
		read REAL_NAME
	done
else
	REAL_NAME="Average User"
	echo "Please enter the username: "
fi

# create the user directory
mkdir /Users/"$DIR_NAME"
echo "mkdir /Users/$DIR_NAME"
echo "Home for $DIR_NAME now located at /Users/$DIR_NAME"
echo "    "

# create the account
# this is two different parts - directory based accounts vs. local accounts.
# directory accounts hasn't been tested at this point, but I will update it as soon as I have a chance to test it.
# it SHOULD work as is.

# this should work when you have a directory service, i.e. AD/OD configured
#/System/Library/CoreServices/ManagedClient.app/Contents/Resources/createmobileaccount -n $DIR_NAME
#echo "Account for $DIR_NAME has been created on this computer"			

# this works for local accounts
echo "Creating...."
/usr/bin/dscl . create /Users/"${DIR_NAME}" # create account
echo "... account"
/usr/bin/dscl . create /Users/"${DIR_NAME}" UserShell /bin/bash # set shell
echo "... shell set"
/usr/bin/dscl . create /Users/"${DIR_NAME}" RealName "$REAL_NAME" # set real name
echo "... real name set"
/usr/bin/dscl . create /Users/"${DIR_NAME}" UniqueID 512 # assign a unique ID
echo "... UID"
# We shouldn't do it this way, since if you move multiple users, they will have the same UID. That's bad. But if you're using this, it's likely for one user, or you will have switched this off and turned on the directory service version.

/usr/bin/dscl . create /Users/"${DIR_NAME}" PrimaryGroupID 20 # assign a primary group
echo "... Primary Group assigned"
/usr/bin/dscl . create /Users/"${DIR_NAME}" NFSHomeDirectory /Users/"${DIR_NAME}" # set the users NFS Home
echo "... NFS Home set"
/usr/bin/dscl . passwd /Users/"${DIR_NAME}" $ACCOUNTPASSWORD
echo "... temp password set"
echo "    "

# ditto the User Template into the user folder
ditto /System/Library/User\ Template/English.lproj /Users/"$DIR_NAME"
echo "Copying from User Template"
echo "Done"
sleep 3
echo "    "

echo "Do you want to give the $DIR_NAME account admin rights?"
select yn in "Yes" "No"; do
		case $yn in
			Yes) /usr/sbin/dseditgroup -o edit -a "$DIR_NAME" -t user admin; echo "Admin rights given to this account"; break;;
			No ) echo "No admin rights given"; break;;
		esac
done
echo "   "
sleep 2

# copy the user data into the home
echo "Copying user data to \"Transfer\" on their Desktop"
mkdir /Users/"$DIR_NAME"/Desktop/Transfer
echo "mkdir /Users/$DIR_NAME/Desktop/Transfer"
echo "   "

ditto -v "$DIR_SOURCE" /Users/"$DIR_NAME"/Desktop/Transfer/
echo "ditto $DIR_SOURCE /Users/$DIR_NAME/Desktop/Transfer/"
echo "  "
sleep 6

# change ownership so that the local/network account has ownership
echo "/usr/sbin/chown -R ${DIR_NAME} /Users/$DIR_NAME"
chflags -R nouchg /Users/"$DIR_NAME"
/usr/sbin/chown -R "${DIR_NAME}" /Users/"$DIR_NAME"

echo "Done."