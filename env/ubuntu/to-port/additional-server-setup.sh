###### 
## disable bash history (security mitigation for if our VM host provider gets hacked)
set +o history
history -c

if grep -xq "^# disable bash history.*" /etc/bash.bashrc
then
: #noop
else
cat >> /etc/bash.bashrc <<EOF

################################
## wrote by $SCRIPT_FILENAME user $ACTUAL_USER on $(DATE) .....
# disable bash history
HISTFILE=\/dev\/null

EOF
fi
rm -f $HOME_DIR/.bash_history