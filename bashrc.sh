#sudo systemctl start docker

#############################################################################################
# window\tab title manipulations:
# will present basename of folder and
# updated automatically when cd is used
#############################################################################################
function title_window() {
  PROMPT_COMMAND="echo -ne \"\033]0;$@\007\""
}

function title_window_basename_pwd() {
  PROMPT_COMMAND="echo -ne \"\033]0;$(basename "$PWD")\007\""
}

title_window_basename_pwd

function cd() {
  command cd "$@"
  title_window_basename_pwd
}
#############################################################################################


#############################################################################################
# changes the pwd to show the real full path
# even if you cd into a symbolic link
set -P

# let everyone write, read and executable (get into directories)
umask -S a+rwx 1> /dev/null

# If ~/.inputrc doesn't exist yet: First include the original /etc/inputrc
# so it won't get overridden
if [ ! -a ~/.inputrc ]; then echo '$include /etc/inputrc' > ~/.inputrc; fi

# Add shell-option to ~/.inputrc to enable case-insensitive tab completion
echo 'set completion-ignore-case On' >> ~/.inputrc

# Source global definitions
#if [ -f /etc/bashrc ]; then
#        . /etc/bashrc
#fi

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=
#############################################################################################

#############################################################################################
# prompt:
#############################################################################################
function parse_git_branch() 
{
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'
     #git branch --show-current 2> /dev/null
}
#export PROMPT_COMMAND='echo -ne "\033]0;${PWD##*/}\007"'
#colourful prompt
# the if [ -t 1 ]; checks whether we are in a window
# Custom bash prompt via kirsle.net/wizards/ps1.html
# \[$(tput setaf 1)\] red
# \[$(tput setaf 2)\] green
# \[$(tput setaf 3)\] yellow
# \[$(tput setaf 4)\] dark blue
# \[$(tput setaf 6)\] cyan
if [ -t 1 ]; then
  # fancier git PS1
  #https://github.com/git/git/blob/master/contrib/completion/git-prompt.sh
  #. git-prompt.sh
  #export PS1="\[$(tput bold)\]\[$(tput setaf 6)\][\[$(tput setaf 3)\]\W\[$(tput setaf 6)\]]\[$(tput setaf 2)\]\[$(tput setaf 4)\]\$(__git_ps1 %s)\[$(tput setaf 2)\]$ \[$(tput sgr0)\]"
  export PS1="\[$(tput bold)\]\[$(tput setaf 6)\][\[$(tput setaf 3)\]\W\[$(tput setaf 6)\]]\[$(tput setaf 2)\]\[$(tput setaf 4)\]\$(parse_git_branch)\[$(tput setaf 2)\]$ \[$(tput sgr0)\]"
fi
#############################################################################################


#############################################################################################
export PAGER=less
export EDITOR=emacs      
export savehist=200         # on logout, save last x commands in ~/.history 
export history=500          # remember last x commands
export inputmode=insert     # or '=overwrite'
export notify               # notify at once when a background job terminates
export noclobber            # to overwrite a file, must use '>!', not '>'
export ignoreeof            # to logout, must use 'exit', not Ctl-D
export correct=cmd          # or '=all'. Try to correct typing errors
export autolist             # so <tab> lists possible completions (like Ctl-D)
export listmax=500          # so autolistings don't clutter screen
#############################################################################################


#############################################################################################
# key bindings
#############################################################################################

# find out what is the keybinding:
# ctrl+v
# key\s click
# 2 clicks: ^[XX => \eXX (XXX can be single\two chars)
# 1 click: ^[[X => \e[X

if [ -t 1 ]; then
    # up and down search in history
    bind '"\e[A":history-search-backward'
    bind '"\e[B":history-search-forward'
    # Set Ctrl+arrows to move a whole word forward/backward
    bind '"\eOD":backward-word'
    bind '"\eOC":forward-word'
fi
#########################################################################


#############################################################################################
#Basic aliases
alias rm='rm -i'         # ask on remove
alias cp='cp -i'         # ask on overwrite
alias mv='mv -i'         # ask on overwrite
alias df='df -h'

#add current path
export PATH=$PATH:

#colorful man pages
export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;37m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'
#############################################################################################
