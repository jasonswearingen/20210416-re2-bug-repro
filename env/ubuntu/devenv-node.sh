#!/bin/bash
# WHAT THIS IS: basic init of ubuntu for dev or server environments

# ensure running sudo: https://electrictoolbox.com/check-user-root-sudo-before-running/
if [ `whoami` != root ]; then
    echo Please run this script using sudo
    exit
fi


# install helper scripts  
if test -f /etc/.bashrc_novaleaf_helpers ; then 
## add to our currently running script (aptgethelper,assertErrorOk)
source /etc/.bashrc_novaleaf_helpers
assertExitOk
else
echo "/etc/.bashrc_novaleaf_helpers not found.  run 'basic-os-setup*.sh' script first"
fi



#verbose log everything to console: https://stackoverflow.com/questions/2853803/how-to-echo-shell-commands-as-they-are-executed
set -x

# SET DEFAULT SCRIPT ENV VARS
SCRIPT_DIR="`dirname \"$0\"`"  # from https://stackoverflow.com/a/3355423/1115220
SCRIPT_DIRNAME=${PWD##*/} # folder name, without full path
HOME_DIR=~
SCRIPT_FILENAME="`basename \"$0\"`"
DATE=`eval date +%Y%m%d`
TIME=`eval date +%H%M`
HOSTNAME=$(hostname)
IP=$(hostname -I | awk '{print $1}')  #from: https://opensource.com/article/18/5/how-find-ip-address-linux
#get the logged in user, even if sudo.  from https://stackoverflow.com/a/4597929/1115220
if [ $SUDO_USER ]; then ACTUAL_USER=${SUDO_USER}; else ACTUAL_USER=$(whoami); fi 


pushd SCRIPT_DIR
################################################################
################################################################
################################################################
#################################   SCRIPT INIT COMPLETE #################
################################################################
################################################################
################################################################


echo %%%%%%%%%% SCRIPT INIT COMPLETE %%%%%%%%%%%%%%%%%%






######  install nodejs v14.x, from: https://github.com/nodesource/distributions/blob/master/README.md#debinstall
# node use useful for scripts, in addition to normal server apps.
# curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash
# Using Ubuntu
curl -fsSL https://deb.nodesource.com/setup_14.x | sudo -E bash -
assertExitOk
# sudo apt-get install -y nodejs
aptgethelper install "nodejs"
assertExitOk
aptgethelper install "build-essential"
assertExitOk


npm install -g yarn pnpm

# if grep -xq "^YARN_CACHE_FOLDER.*" /etc/environment then :; else
# cat >> /etc/environment <<EOF
# YARN_CACHE_FOLDER="/mnt/c/repos/.yarn-cache"
# EOF
# fi
# "YARN_CACHE_FOLDER": "/workspaces/.yarn-cache",



#yarn global add typescript

################################################
###########################  LERNA ##########
# how to use lerna tutorial: https://dev.to/jody/using-lerna-to-manage-your-javascript-monorepo-4eoo
# yarn global add lerna lerna-wizard  
# set username+email which is needed for the lerna tool
# git config --global user.name "${NAME}"
# git config --global user.email "${NAME}"

