#!/bin/sh
# installed to /etc/.bashrc_novaleaf_helpers  by the basic-os-setup script



## bash aliases go here.   for more ideas, see: https://news.ycombinator.com/item?id=18898523


# from https://askubuntu.com/questions/610052/how-can-i-preset-aliases-for-all-users
alias cd..='cd ..'

#function helper to check exit code of commands.  example usage allows 0 or 1:  assertExitOk 1   
function assertExitOk(){
local __errorCode=$?
echo "errorcode= $__errorCode"
local __alsoOk=$1
__alsoOk=${__alsoOk:-0}
if [ $__errorCode -ne 0 ]; then
if [ "$__errorCode" != "$__alsoOk" ]; then
echo "--------------------"
echo " ---   INVALID EXIT CODE '$__errorCode' ENCOUNTERED IN LAST STATEMENT   ABORTING   -----"
echo "--------------------"
exit $__errorCode
fi
fi
}


####  get the logged in user, even if sudo.  from https://stackoverflow.com/questions/3522341/identify-user-in-a-bash-script-called-by-sudo/4597929#4597929
#### HOW TO USE:  VARIABLE=\$\(getActualUser\)
function getActualUser(){
local __user
if [ $SUDO_USER ]; then __user=${SUDO_USER}; else __user=$(whoami); fi
echo "$__user"
}

############ wrapper over apt-get to download files (retries if download fails) and then perform action.  usage example:  aptgethelper install "nethogs rar -y -qq --force-yes"
# docs for apt / apt-get:  http://manpages.ubuntu.com/manpages/cosmic/en/man8/apt-get.8.html
# use apt-get, not apt.  see: https://askubuntu.com/questions/990823/apt-gives-unstable-cli-interface-warning
# order of apt-get parameters matters: https://askubuntu.com/questions/448358/automating-apt-get-install-with-assume-yes
function aptgethelper(){
local __cmd=$1
local __args=$2
local retry=10 count=0
# set +x 
    # retry at most $retry times, waiting 1 minute between each try
    while true; do

        # Tell apt-get to only download packages for upgrade, and send 
        # signal 15 (SIGTERM) if it takes more than 10 minutes		
        if timeout --kill-after=60 60 apt-get --download-only --assume-yes $__cmd $__args; then
            break
        fi
        if (( count++ == retry )); then
            printf "apt-get download failed for $__cmd ,  $__args\n" >&2
            return 1
        fi
        sleep 5
    done

    # At this point there should be no more packages to download, so 
    # install them.
    apt-get --assume-yes -qq  $__cmd $__args
		
}

