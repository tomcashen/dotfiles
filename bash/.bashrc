#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'
PS1='[\u@\h \W]\$ '

[[ -f ~/.bashrc-personal ]] && . ~/.bashrc-personal

source /usr/share/wikiman/widgets/widget.bash
