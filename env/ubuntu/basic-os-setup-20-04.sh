#!/bin/bash
# WHAT THIS IS: basic init of ubuntu for dev or server environments

# more examples here: https://github.com/microsoft/vscode-dev-containers/blob/master/script-library/common-debian.sh

# ensure running sudo: https://electrictoolbox.com/check-user-root-sudo-before-running/
if [ `whoami` != root ]; then
    echo Please run this script using sudo
    exit
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



echo %%%%%%%%%%%%%%%%%%%%  ADD SCRIPT HELPERS %%%%%%%%%%%%%%%%%%


########################################
#######  add helper aliases: https://serverfault.com/questions/491585/is-there-a-global-bash-profile-for-all-users-on-a-system
#########  EXCEPT:  the above doesn't set gnome's terminal properly, or when you "sudo bash" or do non-interactive scripts.   so instead write to ~/.bashrc, as per: https://askubuntu.com/questions/438150/scripts-in-etc-profile-d-being-ignored

cp --force ./helpers/.bashrc_novaleaf_helpers.sh /etc/.bashrc_novaleaf_helpers



### MAYBE need to expand aliases, see: https://www.gnu.org/software/bash/manual/html_node/Aliases.html and https://stackoverflow.com/a/5240914/1115220
##shopt -s expand_aliases

##add to .bashrc, escape the variable: https://unix.stackexchange.com/a/68421/118754
##why /etc/bash.bashrc and not ~/.bashrc: so all users share it.  UBUNTU/DEBIAN ONLY. see: https://askubuntu.com/questions/815066/whats-the-difference-between-bashrc-and-etc-bash-bashrc



if grep -xq "^# bashrc_novaleaf_helpers:.*" /etc/bash.bashrc
then
    echo "skipping injection of bash helpers.  already installed."
: #noop
else
cat >> /etc/bash.bashrc <<EOF

################################
## wrote by $SCRIPT_FILENAME user $ACTUAL_USER on $(DATE) .....
# bashrc_novaleaf_helpers: load our custom shell helpers
if [ -f /etc/.bashrc_novaleaf_helpers ]; then
    source /etc/.bashrc_novaleaf_helpers
fi

EOF
fi


#make helpers executable by everyone, as per: https://askubuntu.com/a/485001
#chmod +111 /etc/.bashrc_novaleaf_helpers

## add to our currently running script (aptgethelper,assertErrorOk)
source /etc/.bashrc_novaleaf_helpers
assertExitOk
if [ $? -ne 0 ]; then
echo "problem setting bashrc helpers".  exiting
exit -1
fi


echo %%%%%%%%%%%%%%%%%%%%  CONFIGURE OS BASICS %%%%%%%%%%%%%%%%%%

########################################
###### setup truely non-interactive
export DEBIAN_FRONTEND=noninteractive #from http://snowulf.com/2008/12/04/truly-non-interactive-unattended-apt-get-install/ and https://bugs.launchpad.net/ubuntu/+source/eglibc/+bug/935681
# note: to use this, need "sudo -E" to copy env variables, otherwise will still get interactive prompts





# update the os packages to latest
aptgethelper update
assertExitOk
aptgethelper upgrade
assertExitOk


#################  upgrade git to latest.   adapted from: https://unix.stackexchange.com/a/170831/118754
aptgethelper install software-properties-common
sudo add-apt-repository ppa:git-core/ppa -y
aptgethelper update
aptgethelper install git -y


## basic apps
#ufw  (firewall)
#expect is an automation tool (propt and reply)
#ne - text editor.  see: http://ne.di.unimi.it/
# 7z  7zip archiver
aptgethelper install "git ufw ne nano nethogs htop expect p7zip-full git-lfs"
assertExitOk
git lfs install
assertExitOk








# #patch for WSL1 ubuntu 20.04, from: https://github.com/microsoft/WSL/issues/5125#issuecomment-619350931
# if [ -z ${WSL_DISTRO_NAME+x} ]; then :; else
# echo %%%%%%%%%%%  WSL1 FIX FOR REALTIME CLOCK %%%%%%%%%%%%%%%%%%%
# sudo add-apt-repository ppa:rafaeldtinoco/lp1871129 -y
# sudo apt update
# sudo apt install libc6=2.31-0ubuntu8+lp1871129~1 libc6-dev=2.31-0ubuntu8+lp1871129~1 libc-dev-bin=2.31-0ubuntu8+lp1871129~1 -y --allow-downgrades
# sudo apt-mark hold libc6
# fi


echo %%%%%%%%%%%%%%%%%%%%  install unatended upgrades %%%%%%%%%%%%%%%%%%


#auto update packages, from https://help.ubuntu.com/lts/serverguide/automatic-updates.html
aptgethelper install "unattended-upgrades"
assertExitOk
##1804 DISABLE: good defaults already in place
# cat > /etc/apt/apt.conf.d/10periodic << EOF
# APT::Periodic::Update-Package-Lists "1";
# APT::Periodic::Download-Upgradeable-Packages "1";
# APT::Periodic::AutocleanInterval "7";
# APT::Periodic::Unattended-Upgrade "1";
# EOF


#run security updates:  https://askubuntu.com/questions/194/how-can-i-install-just-security-updates-from-the-command-line
# https://linuxhint.com/update_ubuntu_2004_command_line/
unattended-upgrade






echo %%%%%%%%%%%%%%%%%%%%  shell config %%%%%%%%%%%%%%%%%%


#install starship, as per: https://danyspin97.org/blog/colorize-your-cli/

if grep -xq "^# starship-prompt:.*" /etc/bash.bashrc
then
: #noop
echo "starship already installed"
else

aptgethelper install grc  #colorizer
assertExitOk

./helpers/starship-install.sh -y
assertExitOk

cat >> /etc/bash.bashrc <<'EOF'

################################
# starship-prompt: load the starship cross-shell prompt: https://starship.rs/
export STARSHIP_CONFIG=/etc/.config/starship.toml
eval "$(starship init bash)"


# prompt-colors: as per https://danyspin97.org/blog/colorize-your-cli/
[[ -s "/etc/profile.d/grc.bashrc" ]] && source /etc/profile.d/grc.bashrc

EOF

fi



echo %%%%%%%%%%%%%%%%%%%%  shell prompt config %%%%%%%%%%%%%%%%%%

# if test -f /etc/.config/starship.toml ; then :; else
#edit prompt
mkdir -p /etc/.config 
cp ./helpers/starship.toml /etc/.config/starship.toml
# fi

echo %%%%%%%%%%%%%%%%%%%%  byobu %%%%%%%%%%%%%%%%%%

####### make sure byobu is available and configured.  byobu is a terminal multiplexer.
### see http://byobu.co/  and also   https://www.digitalocean.com/community/tutorials/how-to-install-and-use-byobu-for-terminal-management-on-ubuntu-16-04
aptgethelper install "byobu"
# start byobu automatically on login
# byobu-enable 
# enable enhanced prompt
sudo -u $ACTUAL_USER byobu-enable-prompt