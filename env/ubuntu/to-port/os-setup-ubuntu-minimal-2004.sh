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

export SERVICEACCOUNT_NAME=runner
# groups allow the app files to be owned by another user, but run by the service account
export SERVICEACCOUNT_GROUPNAME=run-grp
# SERVICEACCOUNT_PUBLICKEYFILE=jason.robert.swearingen@master-20150302.pub
# SERVICEACCOUNT_PUBLICKEYURL="https://github.com/jasonswearingen/devops/raw/master/public-keys/$SERVICEACCOUNT_PUBLICKEYFILE"
export SWAPFILE_SIZE=5G
# TIMEZONE="America/Los_Angeles" #unused.
####################################
####################################



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




##1804 DISABLE
# #enable multiverse packages, from:
#sed -i "/^# deb.*multiverse/ s/^# //" /etc/apt/sources.list
#aptgethelper update
#assertExitOk


##1804 DISABLE
# #download our keyfile for service account use later
# curl -L --retry 20 --retry-delay 2 -o $SERVICEACCOUNT_PUBLICKEYFILE $SERVICEACCOUNT_PUBLICKEYURL



##1804 ADD


#roughly following guide from https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu-14-04
#add service group/user
addgroup $SERVICEACCOUNT_GROUPNAME
#verify exists
getent group $SERVICEACCOUNT_GROUPNAME
assertExitOk
# create system account: https://superuser.com/questions/77617/how-can-i-create-a-non-login-user
useradd --system $SERVICEACCOUNT_NAME --gid $SERVICEACCOUNT_GROUPNAME
#make a home dir for the service, needed for things like pm2 to log/config itself
mkhomedir_helper $SERVICEACCOUNT_NAME



# old way (has home account, which we don't need as it's not interactive)  
#useradd $SERVICEACCOUNT_NAME --create-home --shell /bin/bash --groups $SERVICEACCOUNT_GROUPNAME
#verify exists
# getent passwd $SERVICEACCOUNT_NAME
#  assertExitOk
# #gpasswd -a $SERVICEACCOUNT_NAME sudo
# mkdir /home/$SERVICEACCOUNT_NAME/.ssh
# chmod 700 /home/$SERVICEACCOUNT_NAME/.ssh
# assertExitOk
# cat $SERVICEACCOUNT_PUBLICKEYFILE >> /home/$SERVICEACCOUNT_NAME/.ssh/authorized_keys
# assertExitOk
# chown $SERVICEACCOUNT_NAME:$SERVICEACCOUNT_NAME /home/$SERVICEACCOUNT_NAME -R
# assertExitOk

#allow sudo without passwords.   does not work like this, must be done via the 'visudo' command!!!!!  
## don't know how to automate, and security concern with service account.
#cat >>  /etc/sudoers << EOF
## grant no-password access, from : https://superuser.com/questions/492405/sudo-without-password-when-logged-in-with-ssh-private-keys
#user ALL=(ALL)       NOPASSWD: ALL
#EOF

# only allow key based logins https://askubuntu.com/questions/435615/disable-password-authentication-in-ssh  
# NOTE: this is already the default in ubuntu-minimal-1804
sed -n 'H;${x;s/\#PasswordAuthentication yes/PasswordAuthentication no/;p;}' /etc/ssh/sshd_config > tmp_sshd_config
assertExitOk
cat tmp_sshd_config > /etc/ssh/sshd_config
assertExitOk
rm tmp_sshd_config 
assertExitOk


# disable root login
#sed -n 'H;${x;s/\PermitRootLogin yes/PermitRootLogin no/;p;}' /etc/ssh/sshd_config > tmp_sshd_config
#assertExitOk
#cat tmp_sshd_config > /etc/ssh/sshd_config
#assertExitOk
#rm tmp_sshd_config 
#assertExitOk

# -u devops-serviceSudo 





############################
#2004 add zsh, from: https://kifarunix.com/install-and-setup-zsh-and-oh-my-zsh-on-ubuntu-20-04/
aptgethelper install "zsh"
# #switch to use zsh
# usermod -s $(which zsh) root
# usermod -s $(which zsh) ${ACTUAL_USER}
# usermod -s $(which zsh) ${SERVICEACCOUNT_NAME}
#zsh install process from msft's common-debian.sh script:  https://raw.githubusercontent.com/microsoft/vscode-dev-containers/v0.122.1/script-library/common-debian.sh


# Ensure ~/.local/bin is in the PATH for root and non-root users for bash. (zsh is later)
echo "export PATH=\$PATH:\$HOME/.local/bin" | tee -a /root/.bashrc >> /home/$ACTUAL_USER/.bashrc 
chown $ACTUAL_USER:$ACTUAL_USER /home/$ACTUAL_USER/.bashrc
echo "export PATH=\$PATH:\$HOME/.local/bin" | tee -a /root/.bashrc >> /home/$SERVICEACCOUNT_NAME/.bashrc 
chown $SERVICEACCOUNT_NAME:$SERVICEACCOUNT_GROUPNAME /home/$SERVICEACCOUNT_NAME/.bashrc
# Optionally install and configure zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
echo "export PATH=\$PATH:\$HOME/.local/bin" >> /root/.zshrc


#find the line ZSH_THEME="whatever" in .zshrc and set it to our prefered.
# sed doesn't support non-greedy regexp.  perl can be used as a direct replacement: https://stackoverflow.com/questions/1103149/non-greedy-reluctant-regex-matching-in-sed
# for sed options, see: https://linuxize.com/post/how-to-use-sed-to-find-and-replace-string-in-files/
# perl -pe for stdout (good for debugging).  -pi -e for in-place.
perl -pi -e 's|^ZSH_THEME=".*?"|ZSH_THEME="fino-time"|' /root/.zshrc

cp -R /root/.oh-my-zsh /home/$ACTUAL_USER
cp /root/.zshrc /home/$ACTUAL_USER
sed -i -e "s/\/root\/.oh-my-zsh/\/home\/$ACTUAL_USER\/.oh-my-zsh/g" /home/$ACTUAL_USER/.zshrc
chown -R $ACTUAL_USER:$ACTUAL_USER /home/$ACTUAL_USER/.oh-my-zsh /home/$ACTUAL_USER/.zshrc
# and install zsh for service acct too
cp -R /root/.oh-my-zsh /home/$SERVICEACCOUNT_NAME
cp /root/.zshrc /home/$SERVICEACCOUNT_NAME
sed -i -e "s/\/root\/.oh-my-zsh/\/home\/$SERVICEACCOUNT_NAME\/.oh-my-zsh/g" /home/$SERVICEACCOUNT_NAME/.zshrc
chown -R $SERVICEACCOUNT_NAME:$SERVICEACCOUNT_GROUPNAME /home/$SERVICEACCOUNT_NAME/.oh-my-zsh /home/$SERVICEACCOUNT_NAME/.zshrc




##########  CRONTAB
## config help for crontab here: https://crontab.guru
# ### add cron minimum settings for our devopsService user, if it doesn't already exist (don't want to overwrite existing crons)
if ! [ "$(sudo -u $SERVICEACCOUNT_NAME crontab -l)" ]; then 
cat > /tmp/serviceCron <<EOF

## wrote by $FILENAME user $ACTUAL_USER on $(date) .....
# setup min env, as per: http://askubuntu.com/questions/264607/bash-script-not-executing-from-crontab, including /sbin for ifconfig access
SHELL=/bin/sh
PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/sbin
# for help on scheduling, see sites like https://crontab.guru
EOF
sudo -u $SERVICEACCOUNT_NAME crontab /tmp/serviceCron
rm --force /tmp/serviceCron
fi

# # sudo -u $SERVICEACCOUNT_NAME bash <<EOF
# # PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/sbin
# # cd /tmp
# # if ! [ "$(crontab -l)" ]; then 
	# # echo '# setup min env, as per: http://askubuntu.com/questions/264607/bash-script-not-executing-from-crontab, including /sbin for ifconfig access' > tmpCron
	# # echo "SHELL=/bin/sh" >> tmpCron
	# # echo "PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/sbin" >> tmpCron
	# # crontab tmpCron
	# # rm tmpCron
# # fi
# # EOF


####### create a crontab for the user too
if ! [ "$(sudo -u $ACTUAL_USER crontab -l)" ]; then 
cat > /tmp/userCron <<EOF

## wrote by $FILENAME user $ACTUAL_USER on $(date) .....
# setup min env, as per: http://askubuntu.com/questions/264607/bash-script-not-executing-from-crontab, including /sbin for ifconfig access
SHELL=/bin/sh
PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/sbin
# for help on scheduling, see sites like https://crontab.guru
EOF
sudo -u $ACTUAL_USER crontab /tmp/userCron
rm --force /tmp/userCron
fi

######### also set cron min for root, if it doesn't already exist (don't want to overwrite existing crons)
if ! [ "$(crontab -l)" ]; then 
cat > /tmp/rootCron <<EOF

## wrote by $FILENAME user $ACTUAL_USER on $(date) .....
# setup min env, as per: http://askubuntu.com/questions/264607/bash-script-not-executing-from-crontab, including /sbin for ifconfig access (os-setup-*.sh)
SHELL=/bin/sh
PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/sbin
# for help on scheduling, see sites like https://crontab.guru
EOF
crontab /tmp/rootCron
rm --force /tmp/rootCron
fi

### add to root crontab
crontab -l > /tmp/rootCron
cat >> /tmp/rootCron <<EOF

## wrote by $FILENAME user $ACTUAL_USER on $(date) .....
# remove shutdown notice written by cloud metadata based shutdown script.
@reboot sudo rm --force /srv/INSTANCE_SHUTDOWN
EOF
crontab /tmp/rootCron
rm --force /tmp/rootCron

# # pushd /tmp
# # if ! [ "$(crontab -l)" ]; then 
	# # echo '# setup min env, as per: http://askubuntu.com/questions/264607/bash-script-not-executing-from-crontab, including /sbin for ifconfig access' > tmpCron
	# # echo "SHELL=/bin/sh" >> tmpCron
	# # echo "PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/sbin" >> tmpCron	
	# # echo "# remove shutdown notice for preempted instances google cloud" >> tmpCron
	# # echo "@reboot sudo rm --force /srv/INSTANCE_SHUTDOWN" >> tmpCron
	# # crontab tmpCron
	# # rm tmpCron
# # fi
# # popd





#### configure /tmp
# by default /tmp is deleted every reboot.  
# you can change this.  see: https://askubuntu.com/questions/20783/how-is-the-tmp-directory-cleaned-up/857154#857154
# but you probably should not.








# ####### install stackdriver monitoring agent: https://cloud.google.com/monitoring/agent/install-agent#linux-install
# # allows memory monitoring
# pushd /tmp
# curl -sSO https://dl.google.com/cloudagents/install-monitoring-agent.sh
# sudo bash install-monitoring-agent.sh
# sudo service stackdriver-agent restart
# popd







echo ---------------------------------------------
echo SCRIPT COMPLETE.

#log execution of this script
cat >> /sources/devops.log <<EOF
$FILENAME finish $ACTUAL_USER, $(date) ($HOSTNAME/$IPADDRESS)
EOF