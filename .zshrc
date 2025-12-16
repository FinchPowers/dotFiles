# ~/.zshrc

# Ne rien faire si le shell n'est pas interactif
[[ -o interactive ]] || return

export LANG=fr_CA.UTF-8
export LANGUAGE=fr_CA:fr
export TZ=:Canada/Eastern

# ===================
# Historique (zsh)
# ===================
HISTSIZE=10000        # nombre de lignes gardées en mémoire
SAVEHIST=20000        # nombre de lignes sauvegardées dans le fichier
HISTFILE=$HOME/.zsh_history

setopt APPEND_HISTORY         # append au lieu d’écraser le fichier d'historique
setopt HIST_IGNORE_ALL_DUPS   # ignore les doublons
setopt HIST_IGNORE_SPACE      # ne pas enregistrer les commandes qui commencent par un espace
setopt HIST_FIND_NO_DUPS      # ne pas remontrer plusieurs fois la même entrée

# ===================
# less
# ===================
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# ===================
# chroot (comme dans bash, inoffensif sur macOS)
# ===================
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# ===================
# Titre de la fenêtre xterm
# ===================
case "$TERM" in
  xterm*|rxvt*)
    # Met le titre à user@host:dir avant chaque commande
    precmd() {
      print -Pn "\e]0;${debian_chroot:+($debian_chroot)}%n@%m: %~\a"
    }
    ;;
  *)
    ;;
esac

# ===================
# Couleurs & prompt
# ===================
autoload -Uz colors
colors

case "$TERM" in
  (xterm-256color|xterm-color|xterm|screen|screen-256color|tmux-256color)
    color_prompt=yes;;
esac

if [[ -n "$force_color_prompt" ]]; then
  if command -v tput >/dev/null 2>&1 && tput setaf 1 >/dev/null 2>&1; then
    color_prompt=yes
  else
    color_prompt=
  fi
fi

if [[ "$color_prompt" = yes ]]; then
  # équivalent de ton PS1 bash :
  # user@host:cwd$
  PROMPT='%F{yellow}%n%f@%F{green}%m%f:%F{blue}%~%f$ '
else
  PROMPT='${debian_chroot:+($debian_chroot)}%n@%m:%~$ '
fi
unset color_prompt force_color_prompt

# Couleurs pour ls (utilisé par GNU ls / exa / eza etc.)
LS_COLORS='di=34:fi=0:ln=31:pi=5:so=5:bd=5:cd=5:or=31:mi=0:ex=35:*.rpm=90'
export LS_COLORS

# ===================
# Completion zsh (remplace bash_completion)
# ===================
autoload -Uz compinit
compinit

# ===================
# tmux
# ===================
if [[ -n "$TMUX" ]]; then
  # Fixup per ssh connection vars when inside tmux
  tmux_vars_fixup() {
    eval "$(tmux showenv -s DISPLAY 2>/dev/null)"
    eval "$(tmux showenv -s SSH_AUTH_SOCK 2>/dev/null)"
  }
else
  tmux_vars_fixup() { return; }
fi

# ===================
# Homebrew
# ===================
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

#===============
# PATH variables
#===============
if [ -d "$HOME/local/lib" ] ; then
  export LD_LIBRARY_PATH="$HOME/local/lib:$LD_LIBRARY_PATH"
fi

if [ -d "$HOME/local/bin" ] ; then
  export PATH="$HOME/local/bin:$PATH"
fi

if [ -d "$HOME/local/lib/pkgconfig" ] ; then
  export PKG_CONFIG_PATH="$HOME/local/lib/pkgconfig/"
fi

if [ -d "/opt/homebrew/opt/postgresql@16/bin" ] ; then
  export PATH="/opt/homebrew/opt/postgresql@16/bin:$PATH"
fi

#===============
# pyenv
#===============
if [ -d "$HOME/.pyenv" ] ; then
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  if command -v pyenv 1>/dev/null 2>&1; then
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
  fi
fi

#===============
# nvm
#===============
if [ -d "$HOME/.nvm" ] ; then
  export NVM_DIR="$HOME/.nvm"
  [ -s "/usr/local/opt/nvm/nvm.sh" ] && . "/usr/local/opt/nvm/nvm.sh"
  [ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && . "/usr/local/opt/nvm/etc/bash_completion.d/nvm"
fi

#===============
# Rust / cargo
#===============
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# ===================
# tmux PATH patch
# ===================
if [[ -n "$TMUX" ]]; then
  echo "in tmux, resetting path"
  export PATH="$TMUX_PATH_PATCH"
else
  export TMUX_PATH_PATCH="$PATH"
fi

# ===================
# Fichier d'env perso
# ===================
if [ -f "$HOME/.env" ]; then
  . "$HOME/.env"
fi

# poetry
export PATH="/Users/fmlheureux/.local/bin:$PATH"

# gpg
export GPG_TTY=$(tty)

export EDITOR=nvim

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

source ~/.bash_aliases

# Fn + ←  => Home (début de ligne)
bindkey "\eOH" beginning-of-line

# Fn + →  => End (fin de ligne)
bindkey "\eOF" end-of-line

# Ctrl + ← : reculer d’un mot
bindkey "\e[1;5D" backward-word

# Ctrl + → : avancer d’un mot
bindkey "\e[1;5C" forward-word

bindkey '^W' backward-kill-word
bindkey '^Y' yank

#########################
# Goodies zsh 🎁
#########################

# Options confort
setopt AUTO_CD            # taper un dossier suffit pour y entrer
setopt CORRECT            # corrige (gentiment) certaines fautes de frappe de commandes
setopt EXTENDED_GLOB      # globbing plus puissant
setopt GLOB_DOTS          # inclut les fichiers commençant par . dans les glob
setopt NO_BEEP            # pas de bip relou
setopt AUTO_PARAM_SLASH   # ajoute / après un dossier complété

# Meilleure navigation dans l'historique:
#   - flèche haut/bas = recherche par préfixe (comme dans fish)
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search    # flèche haut
bindkey '^[[B' down-line-or-beginning-search  # flèche bas

# =========================
# fzf (fuzzy finder)
# =========================
if command -v brew >/dev/null 2>&1; then
  FZF_BASE="$(brew --prefix)/opt/fzf"

  # Keybindings et complétion fzf
  [ -f "$FZF_BASE/shell/key-bindings.zsh" ] && source "$FZF_BASE/shell/key-bindings.zsh"
  [ -f "$FZF_BASE/shell/completion.zsh" ]   && source "$FZF_BASE/shell/completion.zsh"

  # Quelques valeurs par défaut (Ctrl+T, Ctrl+R, etc.)
  export FZF_CTRL_R_OPTS='--sort'
fi

# =========================
# zsh-autosuggestions
# (suggestions grises à droite du curseur)
# =========================
if command -v brew >/dev/null 2>&1; then
  ZSH_AUTOSUGGEST_DIR="$(brew --prefix)/share/zsh-autosuggestions"
  if [ -f "$ZSH_AUTOSUGGEST_DIR/zsh-autosuggestions.zsh" ]; then
    # Ne pas intercepter backward-kill-word → préserve le kill-ring
    ZSH_AUTOSUGGEST_IGNORE_WIDGETS+=(backward-kill-word)
    source "$ZSH_AUTOSUGGEST_DIR/zsh-autosuggestions.zsh"
    # Mode "autosuggest" type fish
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
  fi
fi

# =========================
# zsh-syntax-highlighting
# (coloration des commandes en cours de saisie)
# ⚠️ Doit être chargé en DERNIER
# =========================
if command -v brew >/dev/null 2>&1; then
  ZSH_HIGHLIGHT_DIR="$(brew --prefix)/share/zsh-syntax-highlighting"
  if [ -f "$ZSH_HIGHLIGHT_DIR/zsh-syntax-highlighting.zsh" ]; then
    source "$ZSH_HIGHLIGHT_DIR/zsh-syntax-highlighting.zsh"
  fi
fi
