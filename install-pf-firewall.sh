#!/bin/bash

###############################################################################################
# CREATE A BASIC FIREWALL USING PF
# J. Munzo - 2023
#
# This simple script creates a basic firewall using PF.  It restricts connections to standard
# management ports, requiring access to occur exclusively over private, local connections.
#
# PORTS BLOCKED: 5900 (Screen Sharing), 3283 (Reporting), 22 (SSH)
# ACCESSIBLE FROM: 10.0.0.0 - 10.255.255.255, 192.168.0.0 - 192.168.255.255
#
# Additionally, the script adds a LaunchDaemon to the OS, which seeks to ensure that regular 
# OS updates / system reboots do not compromise the integrity of the firewall.
#
# The script must be run as root.
###############################################################################################

# Check for root
if [[ $UID -ne 0 ]]; then echo "Please run $0 as root." && exit 1; fi

####################################################################
# PFSETTINGS
# Contains our "rules" for the firewall.  We block all connections
# to the selected ports, and then allow specific ranges to connect.
#
# pf.conf man page -
# https://man.openbsd.org/pf.conf
####################################################################

/bin/cat > /etc/pf.anchors/com.johnmunzo.pfsettings <<EOF
# Restrict ScreenSharing (port 5900) access
block return in proto { udp, tcp } from any to any port 5900
pass in inet proto { udp, tcp } from 10.0.0.0/8 to any port 5900
pass in inet proto { udp, tcp } from 192.168.0.0/16 to any port 5900

# Restrict ARD Reporting (port 3283) access
block return in proto { udp, tcp } from any to any port 3283
pass in inet proto { udp, tcp } from 10.0.0.0/8 to any port 3283
pass in inet proto { udp, tcp } from 192.168.0.0/16 to any port 3283

# Restrict SSH (port 22) access
block return in proto tcp from any to any port 22
pass in inet proto tcp from 10.0.0.0/8 to any port 22 no state
pass in inet proto tcp from 192.168.0.0/16 to any port 22 no state
EOF

# Set rights
chown -R root:wheel /etc/pf.anchors/com.johnmunzo.pfsettings
chmod -R a+rx /etc/pf.anchors/com.johnmunzo.pfsettings

####################################################################
# CONF FILE
# This takes our custom "rules" from the previously created file,
# and commits them to PF (as an anchor).
#
# pf.conf man page -
# https://man.openbsd.org/pf.conf
####################################################################

/bin/cat > /etc/pf.com.johnmunzo.conf <<EOF
anchor "com.johnmunzo.pf"
load anchor "com.johnmunzo.pf" from "/etc/pf.anchors/com.johnmunzo.pfsettings"
EOF

# Set rights
chown -R root:wheel /etc/pf.com.johnmunzo.conf
chmod -R a+rx /etc/pf.com.johnmunzo.conf

####################################################################
# SHELL SCRIPT
# This creates a script file that will kick off pfctl with our 
# custom configuration.  This file will later be referenced by our
# LaunchDaemon, to ensure persistance across OS updates / reboots.
# 
# pfctl man page -
# https://man.openbsd.org/pfctl
####################################################################

# Check if directory exists
if [ ! -d "/usr/local/bin" ]
then
    mkdir -p /usr/local/bin
fi

/bin/cat > /usr/local/bin/firewall.sh <<EOF
#!/bin/bash
/bin/sleep 10
/usr/sbin/ipconfig waitall
/sbin/pfctl -E -f /etc/pf.com.johnmunzo.conf
EOF

# Set rights
chown -R root:wheel /usr/local/bin/firewall.sh
chmod -R a+rx /usr/local/bin/firewall.sh

####################################################################
# LAUNCHDAEMON
# Creates a LaunchDaemon to consistently run our previous shell
# script.  Ensures persistance across OS updates / system reboots.
#
# launchctl man page -
# https://ss64.com/osx/launchctl.html
####################################################################

/bin/cat > /Library/LaunchDaemons/com.johnmunzo.pfctl.plist <<EOF
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE plist PUBLIC "-//Apple Computer/DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
        <string>com.johnmunzo.pfctl.plist</string>
    <key>Program</key>
        <string>/usr/local/bin/firewall.sh</string>
    <key>RunAtLoad</key>
        <true/>
    <key>LaunchOnlyOnce</key>
        <true/>
    <key>StandardOutPath</key>
        <string>/Library/Logs/pfctl_log.log</string>
    <key>StandardErrorPath</key>
        <string>/Library/Logs/pfctl_error.log</string>
</dict>
</plist>
EOF

# Set rights
chown -R root:wheel /Library/LaunchDaemons/com.johnmunzo.pfctl.plist
chmod -R a+rx /Library/LaunchDaemons/com.johnmunzo.pfctl.plist

# Load the LaunchDaemon
launchctl load -w /Library/LaunchDaemons/com.johnmunzo.pfctl.plist

# END OF SCRIPT
exit 0
