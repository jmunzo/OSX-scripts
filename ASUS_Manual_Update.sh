#!/bin/bash

# ASUS Manual Update Utility
# J. Munzo - 2016
# Columbia University Libraries

# Special thanks to the JAMF Nation Community for discovering this workaround
# Official thread documenting issues and community troubleshooting:
# https://jamfnation.jamfsoftware.com/discussion.html?id=17437

# NOTES:
# Script to manually enable/disable updates on ASUS
# Script must be run as root
# Server.app cannot be running during this process

# Specifically targets /Library/Server/Software Update/Data/html/
# and /Library/Server/Software Update/Data/html/content folders

# Print script information
echo "";
echo "***************************************************************************";
echo "*                                                                         *";
echo "*                     ASUS Manual Update Utility 2.3                      *";
echo "*                             J. Munzo - 2016                             *";
echo "*                                                                         *";
echo "* This utility will allow you to manually enable/disable updates on ASUS. *";
echo "*             Server.app cannot be running during this process.           *";
echo "*                                                                         *";
echo "*               Special thanks to the JAMF Nation Community               *";
echo "*    Official thread documenting issues and community troubleshooting:    *";
echo "*       https://jamfnation.jamfsoftware.com/discussion.html?id=17437      *";
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
echo "This script will shutdown Server.app if it is running,";
echo "as well as stop the SWUpdate service.";
echo "";
echo "Press any key to begin...";
read -n1 _null

# Stop Server.app if it is running
echo "Closing Server.app...";
echo "------------------------------------------------------------------------";
killall "Server"
echo "------------------------------------------------------------------------";
echo "Server.app closed.";
echo "";
echo "**********";
echo "";

# Stop the SWUpdate Service
echo "Now stopping SWUpdate Services...";
echo "------------------------------------------------------------------------";
serveradmin stop swupdate
echo "------------------------------------------------------------------------";
echo "SWUpdate Services successfully stopped.";

# BEGIN REPEAT

# Set the variable for repeating the sequence
_repeat="Y"

# While loop to repeat this sequence to add multiple updates at a time
while [ $_repeat = "Y" ]
do

	# Set default _uuid variable
	_uuid="not selected"

	# Separate out content, so user reads instructions
	echo "";
	echo "**********";
	echo "";

	# Inform the user about Software Update Product IDs
	echo "Apple Software Updates are each given a Product ID.";
	echo "These Product IDs can be determined by highlighting the update";
	echo "within the Server GUI, and selecting View Update,";
	echo "or by double-clicking the update.";
	echo "";
	echo "Example Product IDs:";
	echo "031-62987";
	echo "zzzz031-62987";
	echo "11G56_ServerAdminTools";
	echo "";

	# Prompt for Software Update Product ID
	echo "Please input the Product ID exactly as it appears within the Server GUI: ";
	read _uuid
	echo "";

	# Check the Product ID
	echo "You have selected Update $_uuid";

	# CHECK STATUS OF UPDATE
	# If the update doesn't exist we want to skip it, so we set a skip variable
	_skip=0
	_utoggle=""
	_switch=""

	# Set variables to check the status of a selected Product ID, as well as the full name of the selected update
	_status=`/usr/libexec/PlistBuddy -c 'print workingSetProducts:'$_uuid':enable' /Library/Server/Software\ Update/Status/com.apple.server.swupdate.plist`
	_uname=`/usr/libexec/PlistBuddy -c 'print workingSetProducts:'$_uuid':localization:English:title' /Library/Server/Software\ Update/Status/com.apple.server.swupdate.plist`

	# If applicable, report the status and set appropriate variables for toggling enabled/disabled status
	if [ $_status == false ]; then
		echo "$_uname is currently Disabled";
		_skip=1
		_utoggle=1
		_switch="enable"
	elif [ $_status == true ]; then
		echo "$_uname is currently Enabled";
		_skip=1
		_utoggle=2
		_switch="disable"

	# If update does not exist, or other error occurs, report issue and skip it
	else
		echo "";
		echo "Invalid selection.";
		echo "Update $_uuid does not exist...";
		_skip=0
	fi
	echo "";

	# If the update exists, proceed
	if [ $_skip == 1 ]; then
		# Prompt the user to toggle the update
		echo -n "Would you like to $_switch this update? (Y/N)";
		read -n1 _utoggle;

		# Anticipate uppercase/lowercase discrepancy
		case $_utoggle in
			[Nn])
			_utoggle="N"
			;;
		esac
		case $_utoggle in
			[Yy])
			_utoggle="Y"
			;;
		esac
		echo "";
		echo "";

		# Process Enable/Disable of update based upon user input and status of update
		if [ $_status == false ] && [ $_utoggle == "Y" ]; then
			echo "Setting $_uname to Enabled Status...";
			/usr/libexec/PlistBuddy -c 'set workingSetProducts:'$_uuid':enable YES' /Library/Server/Software\ Update/Status/com.apple.server.swupdate.plist
			echo "$_uname has been Enabled.";
		elif [ $_status == true ] && [ $_utoggle == "Y" ]; then
			echo "Setting $_uname to Disabled Status...";
			/usr/libexec/PlistBuddy -c 'set workingSetProducts:'$_uuid':enable NO' /Library/Server/Software\ Update/Status/com.apple.server.swupdate.plist
			echo "$_uname has been Disabled.";
		else
			echo "No changes made...";
		fi
		echo "";

	# If the update doesn't exist, skip to this point
	fi

	# Prompt for additional updates
	echo -n "Would you like to modify another update package? (Y/N)";
	read -n1 _another;
	echo "";

	# If user fails to enter 'n' or 'N', the script will loop
	# Anticipate uppercase/lowercase discrepancy
	case $_another in
		[Nn])
		_repeat="N"
		;;
	esac
done
echo "";

# END REPEAT

# Separate out content, so user reads instructions
echo "**********";
echo "";

# Prompt before deletion of files and restart of SWUpdate services
echo "This script will now delete the following files and folders:";
echo "/Library/Server/Software Update/Data/html/*.sucatalog";
echo "/Library/Server/Software Update/Data/html/*.alternate";
echo "/Library/Server/Software Update/Data/html/content/catalogs";
echo "";
echo "Catalogs will be re-synced following deletion, and SWUpdate services";
echo "will be restarted upon completion.";
echo "";
echo "Press any key to begin...";
read -n1 _null
echo "";

# Delete the cached catalog files
echo "Deleting cached catalog files...";
echo "------------------------------------------------------------------------";
rm -Rfv /Library/Server/Software\ Update/Data/html/*.sucatalog
rm -Rfv /Library/Server/Software\ Update/Data/html/*.alternate
rm -Rfv /Library/Server/Software\ Update/Data/html/content/catalogs
echo "------------------------------------------------------------------------";
echo "Cached catalogs deleted.";
echo "";
echo "**********";
echo "";

# Resync the catalogs
echo "Beginning synchronization of catalogs.  This can take several minutes...";
echo "------------------------------------------------------------------------";
swupd_syncd -sync
echo "------------------------------------------------------------------------";
echo "Synchronization completed.";
echo "";
echo "**********";
echo "";

# Restart the SWUpdate Service
echo "Now starting SWUpdate Services...";
echo "------------------------------------------------------------------------";
serveradmin start swupdate
echo "------------------------------------------------------------------------";
echo "SWUpdate Services successfully started.";
echo "";
echo "**********";
echo "";

# End the script
echo "Thank you for using ASUS Manual Update!";
echo "";
exit 0;

# TO-DO:
# Check if folder structure exists before continuing the script
#
# Optimize, optimize, optimize...
