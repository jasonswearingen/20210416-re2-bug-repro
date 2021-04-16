#!/bin/bash

#### WHAT IS THIS:  basic configuration + security hardening of the os for our cloud vm usage
### minimally adapted to run on google-cloud
## to run, need to sudo this .sh script.

######  OTHER NOTES FOR LATER:
### Checking if output of a command contains a certain string in a shell script
###  https://stackoverflow.com/questions/16931244/checking-if-output-of-a-command-contains-a-certain-string-in-a-shell-script
# also see http://stackoverflow.com/questions/1941242/the-not-so-useless-yes-bash-command-how-to-confirm-a-command-in-every-loop
# backticks vs braces: https://stackoverflow.com/a/22709390/1115220


####################################
####################################
#Vars YOU MUST CONFIGURE!!!  #SET THIS IN THE ROOT SCRIPT, (or do it here if running one-off)

SERVICEACCOUNT_NAME=devops-service
# groups allow the app files to be owned by another user, but run by the service account
SERVICEACCOUNT_GROUPNAME=service-runner
# SERVICEACCOUNT_PUBLICKEYFILE=jason.robert.swearingen@master-20150302.pub
# SERVICEACCOUNT_PUBLICKEYURL="https://github.com/jasonswearingen/devops/raw/master/public-keys/$SERVICEACCOUNT_PUBLICKEYFILE"
export SWAPFILE_SIZE=5G
# TIMEZONE="America/Los_Angeles" #unused.
####################################
####################################


## https://stackoverflow.com/questions/2853803/how-to-echo-shell-commands-as-they-are-executed
set -x

######### pre-prep environment vars #########
### get our homedir, as it seems the ~ var gets destroyed later...
homedir=~
MY_PATH="`dirname \"$0\"`"
FILENAME="`basename \"$0\"`"
pushd $MY_PATH
MY_PATH=$(pwd)
MY_FOLDER=${PWD##*/} # folder name, without full path

nowDate=`eval date +%Y%m%d`
nowTime=`eval date +%H%M`
#now=`eval date +%Y%m%d":"%H%M` #not using this incase minute changes between this and previous line
now=$nowDate:$nowTime

#get host name/ip (printenv to see env vars)
HOSTNAME=$(hostname)
IPADDRESS=$(ifconfig eth0 | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')


####  get the logged in user, even if sudo.  from https://stackoverflow.com/a/4597929/1115220
if [ $SUDO_USER ]; then ACTUAL_USER=${SUDO_USER}; else ACTUAL_USER=$(whoami); fi
echo "Actual user is $ACTUAL_USER"

# # # ########  
# # # ###  commenting mkdir out.  as the deployment script actually creates this, and after deployment it needs to lock down this folder anyway.
# # # mkdir /sources
# # # chown $ACTUAL_USER /sources
# # # ###  chmod command.  docs here: https://www.computerhope.com/unix/uchmod.htm
# # # #does the following, in this order:
# # # # reset file permissions to nothing, (all get nothing)
# # # #give user readwrite+dir-listing
# # # #give group read+dir listing
# # # #give other nothing
# # # chmod -R a=,u=rw+X,g=r+X,o= /sources

#log execution of this script
touch /sources/devops.log
chown $ACTUAL_USER:$ACTUAL_USER /sources/devops.log
cat >> /sources/devops.log <<EOF
$FILENAME start $ACTUAL_USER, $(date) ($HOSTNAME/$IPADDRESS)
EOF
###################################


#firewall, kinda from here: https://www.digitalocean.com/community/tutorials/additional-recommended-steps-for-new-ubuntu-14-04-servers
#more hints+config tricks, like enabling ipv6 here: https://www.digitalocean.com/community/tutorials/how-to-setup-a-firewall-with-ufw-on-an-ubuntu-and-debian-cloud-server
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh/tcp comment "Rate limit ssh, max 6 in 30 seconds set at end of "
ufw logging off
yes | ufw enable
assertExitOk

##1804 DISABLE: gcp already set to UTC
# #timezone/ntp sync
# #echo $TIMEZONE > /etc/timezone
# #dpkg-reconfigure -f noninteractive tzdata
# #ntp
# aptgethelper install "ntp -y -qq --force-yes"


#swap files, simple instructions from https://www.digitalocean.com/community/tutorials/how-to-add-swap-space-on-ubuntu-18-04
fallocate -l $SWAPFILE_SIZE /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
swapon --show
##1804 DISABLE
# sh -c 'echo "/swapfile none swap sw 0 0" >> /etc/fstab'

#fail2ban https://www.digitalocean.com/community/tutorials/how-to-install-and-use-fail2ban-on-ubuntu-14-04
# also see: https://www.techrepublic.com/article/how-to-install-fail2ban-on-ubuntu-server-18-04/
# aptgethelper install "fail2ban"
# systemctl start fail2ban
# systemctl enable fail2ban
# cat >> /etc/fail2ban/jail.local <<EOF

# ## wrote by $FILENAME user $ACTUAL_USER on $(date) .....
# [sshd]
# enabled = true
# port = 22
# filter = sshd
# logpath = /var/log/auth.log
# maxretry = 3
# bantime = 600
# EOF
# systemctl restart fail2ban

# #newrelic server logging, from: https://rpm.newrelic.com/accounts/926338/servers/get_started
# echo deb http://apt.newrelic.com/debian/ newrelic non-free >> /etc/apt/sources.list.d/newrelic.list
# wget -O- https://download.newrelic.com/548C16BF.gpg | apt-key add -
# aptgethelper update
# aptgethelper install "newrelic-sysmond -y -qq --force-yes"
# nrsysmond-config --set license_key=$NEWRELIC_LICENSEKEY
# /etc/init.d/newrelic-sysmond start



echo ---------------------------------------------
echo SCRIPT COMPLETE.

#log execution of this script
cat >> /sources/devops.log <<EOF
$FILENAME finish $ACTUAL_USER, $(date) ($HOSTNAME/$IPADDRESS)
EOF