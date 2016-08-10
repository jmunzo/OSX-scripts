#!/bin/bash

# ASUS Manual Update Utility
# John Munzo - 2016
# Columbia University Libraries
# john.munzo@columbia.edu

# Script to manually enable/disable updates on ASUS
# Script must be run as root
# Server.app cannot be running during this process

# Specifically targets /Library/Server/Software Update/Data/html/
# and /Library/Server/Software Update/Data/html/content folders

# Print script information
echo "";
echo "***************************************************************************";
echo "*                     ASUS Manual Update Utility 2.0                      *";
echo "*                            John Munzo - 2016                            *";
echo "*                                                                         *";
echo "* This utility will allow you to manually enable/disable updates on ASUS. *";
echo "*             Server.app cannot be running during this process.           *";
echo "*                                                                         *";
echo "***************************************************************************";
echo "";
echo "";

# Check if root
if [ "$(whoami)" != "root" ]; then
	echo "Sorry, you are not running as root.";
	echo "Please run this application as root.";
	echo "";
	echo "Exiting script...";
	exit 1
fi

# If root, begin the script
echo "Press any key to begin...";
read -n1 _null

# Stop Server.app if it is running
echo "Closing Server.app...";
killall "Server"
echo "Server.app closed.";
echo "";

# Stop the SWUpdate Service
echo "Now stopping SWUpdate Services...";
serveradmin stop swupdate
echo "SWUpdate Services successfully stopped.";
echo "";

# LOOPBACK BEGINNING

# Set the variable for repeating the sequence
_repeat="Y"

# While loop to repeat this sequence to add multiple updates at a time
while [ $_repeat = "Y" ]
do

	# Set default _uuid variable
	_uuid="not selected"
	echo "";
	echo "The currently targeted update is $_uuid";
	echo "";

	# Inform the user about Software Update UIDs
	echo "Apple Software Updates are each given a Unique Identifier (UID).";
	echo "These UIDs can be determined by highlighting the update";
	echo "within the ASUS GUI, and selecting View Update,";
	echo "or by double-clicking the update.";
	echo "";
	echo "These UIDs can appear in the following formats -";
	echo "031-62987";
	echo "zzzz031-62987";
	echo "11G56_ServerAdminTools";
	echo "";

	# Prompt for Software Update UID
	echo "Please input the update UID exactly as it appears within the ASUS GUI: ";
	read _uuid
	echo "";

	# Check the UID
	echo "You have selected Update $_uuid";

	# CHECK STATUS OF UPDATE
	# If update doesn't exist, we want to skip it
	# Set skip variable
	_skip=0
	_status=`/usr/libexec/PlistBuddy -c 'print workingSetProducts:'$_uuid':enable' /Library/Server/Software\ Update/Status/com.apple.server.swupdate.plist`
	if [ $_status == false ]; then
		echo "Update $_uuid is currently Disabled";
		_skip=1
	elif [ $_status == true ]; then
		echo "Update $_uuid is currently Enabled";
		_skip=1
	else
		echo "Update $_uuid does not exist...";
		_skip=0
	fi
	echo "";

# If the update exists, proceed
if [ $_skip == 1 ]; then
	# Inform the user about Enable/Disable of Update and set default _utoggle variable
	_utoggle="not selected"
	echo "Would you like to Enable or Disable this update?";
	echo "1. Enable";
	echo "2. Disable";
	echo "";

	# Prompt for Enable/Disable of Update
	echo -n "Please enter the number that corresponds with your selection (1 or 2): ";
	read _utoggle;
	echo "";

	# Process Enable/Disable of Update based upon user input
	if [ $_utoggle == 1 ]; then
		echo "Setting Update $_uuid to Enabled Status...";
		/usr/libexec/PlistBuddy -c 'set workingSetProducts:'$_uuid':enable YES' /Library/Server/Software\ Update/Status/com.apple.server.swupdate.plist
		echo "Update $_uuid has been Enabled.";
	elif [ $_utoggle == 2 ]; then
		echo "Setting Update $_uuid to Disabled Status...";
		/usr/libexec/PlistBuddy -c 'set workingSetProducts:'$_uuid':enable NO' /Library/Server/Software\ Update/Status/com.apple.server.swupdate.plist
		echo "Update $_uuid has been Disabled.";
	else
		echo "Invalid selection.  No changes made...";
	fi
	echo "";

# If the update doesn't exist, skip to this point
else
	:
fi
	# Prompt for additional updates
	echo -n "Would you like to modify another update? (Y/N)";
	read -n1 _another;
	echo "";
	case $_another in
		[Nn])
		_repeat="N"
		;;
	esac
done
echo "";

# LOOPBACK END

# Delete the cached catalog files
echo "Deleting cached catalog files...";
rm -Rf /Library/Server/Software\ Update/html/*.sucatalog
rm -Rf /Library/Server/Software\ Update/html/*.alternate
rm -Rf /Library/Server/Software\ Update/html/content/catalogs
echo "Cached catalogs deleted.";
echo "";

# Resync the catalogs
echo "Beginning synchronization of catalogs.  This can take a few minutes...";
swupd_syncd -sync
echo "Synchronization completed.";
echo "";

# Restart the SWUpdate Service
echo "Now starting SWUpdate Services...";
serveradmin start swupdate
echo "SWUpdate Services successfully started.";
echo "";
exit 0;

# TO-DO:
# Nothing :)
