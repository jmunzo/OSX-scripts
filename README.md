# OSX-scripts
OSX related scripts I use to automate workflow at my job.

# ASUS_Manual_Update.sh
This script is a (hopefully temporary) workaround for a bug in Apple Software Update, where updates will disable themselves automatically.

The script works by manually setting specific updates (via UID) to enabled/disabled status directly in the .plist, and resynchronizing the catalogs.  You can toggle multiple updates on and off before synchronizing, and specific update status is reported with each selection.
