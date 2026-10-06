# main checkout of the current repo, from any of its worktrees
_wt_main() {
  local common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || return 1
  echo ${common:h}          # …/aws/master/.git → …/aws/master
}
_wt_root() { local m=$(_wt_main) && echo ${m:h}; }   # → …/aws

# default branch per repo (dagster may use main, aws uses master)
_wt_base() { git -C $(_wt_main) symbolic-ref --short refs/remotes/origin/HEAD | sed 's|^origin/||'; }

wt-new() {
  local main=$(_wt_main) root=$(_wt_root) name=$1 base=${2:-$(_wt_base)}
  [[ -n $main ]] || { echo "not in a git repo"; return 1; }
  git -C $main fetch -q origin $base || return
  git -C $main worktree add -b $name $root/$name origin/$base --no-track || return
  cd $root/$name && git-spice branch track --base $base
}

# Edit this list when new repos follow the worktree pattern
WT_REPOS=(~/workspace/aws/master)

wt-go() {
  local d=$(for m in $WT_REPOS; do git -C $m worktree list; done | fzf --height 40% | awk '{print $1}')
  [[ -n $d ]] && cd $d
}

# wt rm → sync merged branches, then remove the current worktree if its stack is fully merged
wt-rm() {
  local main=$(_wt_main) d=$PWD
  [[ -n $main && $d != $main ]] || { echo "run from a linked worktree"; return 1; }
  git-spice repo sync || return
  local b=$(git branch --show-current)
  if [[ -n $b ]] && git show-ref -q --verify refs/heads/$b; then
    echo "branch $b is not merged yet; keeping the worktree"; return 1
  fi
  cd $main && git worktree remove $d
}

# wt clean [-n] → remove every clean worktree whose branch is merged, then sync git-spice.
# Squash merges defeat `git branch --merged`, so "merged" means GitHub has a merged PR whose
# head is exactly this branch's tip (a reused name or post-merge commits keep the worktree),
# or git-spice already deleted the branch. Worktrees go first: git refuses to delete a branch
# checked out in any worktree, so sync can only prune these branches afterwards.
wt-clean() {
  local main=$(_wt_main) dry=0 d b tip merged
  [[ -n $main ]] || { echo "not in a git repo"; return 1; }
  [[ $1 == -n ]] && dry=1
  local -a gone
  git -C $main worktree list --porcelain | awk '/^worktree/{d=$2} /^branch/{print d, $2}' |
  while read d b; do
    [[ $d == $main ]] && continue
    b=${b#refs/heads/}
    if tip=$(git -C $main rev-parse -q --verify refs/heads/$b); then
      merged=$(cd $main && gh pr list --head $b --state merged --json headRefOid -q '.[].headRefOid' </dev/null)
      (( ${${(f)merged}[(Ie)$tip]} )) || continue
    fi
    if [[ -n $(git -C $d status --porcelain) ]]; then
      echo "skip  ${d##*/}: merged but dirty"; continue
    fi
    echo "clean ${d##*/} ($b)"
    (( dry )) && continue
    [[ $PWD/ == $d/* ]] && cd $main
    git -C $main worktree remove $d && gone+=$b
  done
  (( dry || ! $#gone )) && return
  git-spice -C $main repo sync
  for b in $gone; do
    git -C $main show-ref -q --verify refs/heads/$b && git -C $main branch -D $b
  done
}

# wt ls → one line per worktree: folder, branch, dirty count, behind/ahead of the default branch
wt-ls() {
  local main=$(_wt_main) base=$(_wt_base)
  [[ -n $main ]] || { echo "not in a git repo"; return 1; }
  git -C $main worktree list --porcelain | awk '/^worktree/{print $2}' | while read d; do
    printf '%-40s %-40s %3s dirty  %s\n' "${d##*/}" \
      "$(git -C $d branch --show-current)" \
      "$(git -C $d status --porcelain | wc -l | tr -d ' ')" \
      "$(git -C $d rev-list --left-right --count origin/$base...HEAD 2>/dev/null | awk '{print "-"$1" +"$2}')"
  done
}

wt-help() {
  cat <<'EOF'
usage: wt <command> [args]

  new <name> [base]  create worktree <name> on a new branch from origin/<base>, track it
                     in git-spice, and cd into it (base defaults to the repo's default branch)
  go                 fzf-pick a worktree across $WT_REPOS and cd into it
  ls                 list this repo's worktrees: folder, branch, dirty count, behind/ahead
  rm                 git-spice repo sync, then remove the current worktree if its stack is merged
  clean [-n]         remove every clean worktree whose PR is merged, then git-spice repo sync
                     (-n: only list what would be removed)
  help               show this help

new, ls, rm and clean act on the repo of the current directory.
EOF
}

wt() {
  local c=${1:-help}
  (( $# )) && shift
  if (( ! $+functions[wt-$c] )); then
    echo "wt: unknown command '$c'" >&2
    wt-help >&2
    return 1
  fi
  wt-$c "$@"
}

