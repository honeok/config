# ~/.bashrc: executed by bash(1) for non-login shells.

export LC_ALL=en_US.utf8
export LANG=en_US.utf8

# history appending
shopt -s histappend
# timestamps in history
export HISTTIMEFORMAT='%F %T '

# Note: PS1 and umask are already set in /etc/profile. You should not
# need this unless you want different defaults for root.
# PS1='${debian_chroot:+($debian_chroot)}\h:\w\$ '
# umask 022

if [ -n "$PS1" ]; then
    PS1='\[\033[92m\]\u\[\033[93m\]@\[\033[96m\]\h\[\033[00m\]:\[\033[01;33m\]\w\[\033[01;35m\]\$\[\033[00m\] '
fi

# You may uncomment the following lines if you want `ls' to be colorized:
export LS_OPTIONS='--color=auto'
eval "$(dircolors)"
alias ls='ls $LS_OPTIONS'
alias ll='ls $LS_OPTIONS -l'
alias l='ls $LS_OPTIONS -lA'
#
# Some more alias to avoid making mistakes:
# alias rm='rm -i'
# alias cp='cp -i'
# alias mv='mv -i'

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi