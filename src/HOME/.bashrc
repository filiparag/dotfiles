#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

alias ls='ls --color=auto'

export PS1="\[\e[31m\]┌\[\e[m\]\[\e[36m\]\u\[\e[m\]@\[\e[36m\]\h\[\e[m\] \w\n\[\e[31m\]└\[\e[m\]\\$ "
