# OSX-scripts
OSX related scripts I use to automate workflow at my job.

# ASUS_Manual_Update.sh
This script is a (hopefully temporary) workaround for a bug in Apple Software Update, where updates will disable themselves automatically.

The following files are modified by this script:
/Library/Server/Software Update/Status/com.apple.server.swupdate.plist

The following files and folders are deleted by this script (and later re-synchronized from Apple's servers):
/Library/Server/Software Update/Data/html/*.sucatalog
/Library/Server/Software Update/Data/html/*.alternate
/Library/Server/Software Update/Data/html/content/catalogs

The script works by manually setting specific updates (via Product ID) to enabled/disabled status directly in the swupdate.plist, and resynchronizing the catalogs.  You can toggle multiple updates on and off before synchronizing, and specific update status is reported with each selection.  The script checks user submissions against existing update packages, and prevents erroneous modifications to swupdate.plist.

Tested successfully on OSX 10.11.3 running Server 5.0.15, and OSX 10.11.6 running Server 5.1.7.

Special thanks to the JAMF Nation Community, who thoroughly documented, tested and discovered the workaround for this bug.
The official thread, with the manual solution can be found here:
https://jamfnation.jamfsoftware.com/discussion.html?id=17437
