# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

export LANG=fr_CA.UTF-8
export LANGUAGE=fr_CA:fr
export TZ=:Canada/Eastern

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth
HISTORY_IGNORE="(ls|pwd|exit)*"

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=10000
HISTFILESIZE=20000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if [ -f /etc/bash_completion ] && ! shopt -oq posix; then
    . /etc/bash_completion
fi

# colorss
case "$TERM" in
    xterm-256color | xterm-color | xterm | screen | screen-256color | tmux-256color ) color_prompt=yes;;
esac

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
        # We have color support; assume it's compliant with Ecma-48
        # (ISO/IEC-6429). (Lack of such support is extremely rare, and such
        # a case would tend to support setf rather than setaf.)
        color_prompt=yes
     else
        color_prompt=
     fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='\[\033[0;33m\]\u\[\033[0m\]@\[\033[0;32m\]\h\[\033[0m\]:\[\033[0;34m\]\w\[\033[0m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

LS_COLORS='di=34:fi=0:ln=31:pi=5:so=5:bd=5:cd=5:or=31:mi=0:ex=35:*.rpm=90'
export LS_COLORS

if [ -n "$TMUX" ]; then
    # Fixup per ssh connection vars when inside tmux
    tmux_vars_fixup() {
        eval $(tmux showenv -s DISPLAY)
        eval $(tmux showenv -s SSH_AUTH_SOCK)
    }
else
    tmux_vars_fixup() { return; }
fi

eval "$(/opt/homebrew/bin/brew shellenv)"

#===============
# PATH variables
#===============
if [ -d "$HOME/local/lib" ] ; then
    LD_LIBRARY_PATH="$HOME/local/lib:$LD_LIBRARY_PATH"
    export LD_LIBRARY_PATH
fi
# Add local directory for libraries, etc
if [ -d "$HOME/local/bin" ] ; then
    PATH="$HOME/local/bin:$PATH"
fi

if [ -d "$HOME/local/lib/pkgconfig" ] ; then
    PKG_CONFIG_PATH=$HOME/local/lib/pkgconfig/
fi

if [ -d "/opt/homebrew/opt/postgresql@16/bin" ] ; then
    export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"
fi

#===============
# pyenv ========
#===============
if [ -d "$HOME/.pyenv" ] ; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    if command -v pyenv 1>/dev/null 2>&1; then
      eval $(pyenv init --path)
      eval "$(pyenv init -)"
    fi
fi

#===============
# nvm ==========
#===============
if [ -d "$HOME/.nvm" ] ; then
    export NVM_DIR="$HOME/.nvm"
      [ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"  # This loads nvm
      [ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && . "/usr/local/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion
fi

. "$HOME/.cargo/env"


if [ -n "$TMUX" ]; then
    echo "in tmux, resetting path"
    export PATH=$TMUX_PATH_PATCH
else
    export TMUX_PATH_PATCH=$PATH
fi

if [ -f ~/.env ]; then
    . ~/.env
fi

# poetry
export PATH="/Users/fmlheureux/.local/bin:$PATH"

# gpg
export GPG_TTY=$(tty)

export EDITOR=nvim
. "$HOME/.cargo/env"
