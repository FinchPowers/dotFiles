alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias ls='ls -G'

alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

alias gmu="git checkout master && git fetch && git rebase origin/master && git submodule update"

vimVenAutoload() {
    # run vim in venv if it exists
    if [ -e .venv/bin/activate ]; then
        . .venv/bin/activate;
        vim $*;
        deactivate;
    else
        vim $*;
    fi;
}
alias vim="vimVenAutoload"
