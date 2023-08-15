# OSX-scripts
OSX related scripts I use to automate workflow at my job.

# install-pf-firewall.sh
This script deploys a basic firewall to a target computer, which leverages PF to block all connections to the major ports used for remote-management / access.  It then allows private, local IP ranges to access those ports.  A final touch is the creation of a LaunchDaemon, which triggers a shell script to activate the pfctl service with our custom configuration, ensuring that the firewall remains active through OS updates and system reboots.

The following files are created by this script: <br />
/etc/pf.anchors/com.johnmunzo.pfsettings <br />
/etc/pf.com.johnmunzo.conf <br />
/usr/local/bin/firewall.sh <br />
/Library/LaunchDaemons/com.johnmunzo.pfctl.plist <br />

The following ports are restricted by this configuration:
5900 (Screen Sharing) <br />
3283 (Reporting) <br />
22 (SSH) <br />

The following IP ranges are able to connect:
10.0.0.0 - 10.255.255.255 <br />
192.168.0.0 - 192.168.255.255 <br />


# ASUS_Manual_Update.sh
THIS SCRIPT IS DEPRECATED - APPLE PROFILE MANAGER IS DEAD
This script is a (hopefully temporary) workaround for a bug in Apple Software Update, where updates will disable themselves automatically.

The following files are modified by this script: <br />
/Library/Server/Software Update/Status/com.apple.server.swupdate.plist

The following files and folders are deleted by this script (and later re-synchronized from Apple's servers): <br />
/Library/Server/Software Update/Data/html/*.sucatalog <br />
/Library/Server/Software Update/Data/html/*.alternate <br />
/Library/Server/Software Update/Data/html/content/catalogs <br />

The script works by manually setting specific updates (via Product ID) to enabled/disabled status directly in the swupdate.plist, and resynchronizing the catalogs.  You can toggle multiple updates on and off before synchronizing, and specific update status is reported with each selection.  The script checks user submissions against existing update packages, and prevents erroneous modifications to swupdate.plist.

Tested successfully on OSX 10.11.3 running Server 5.0.15, and OSX 10.11.6 running Server 5.1.7.

Special thanks to the JAMF Nation Community, who thoroughly documented, tested and discovered the workaround for this bug. <br />
The official thread, along with the manual solution, can be found here: <br />
https://jamfnation.jamfsoftware.com/discussion.html?id=17437
