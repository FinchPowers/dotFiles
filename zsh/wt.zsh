# main checkout of the current repo, from any of its worktrees
_wt_main() {
  local common
  common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || return 1
  echo ${common:h}          # …/aws/master/.git → …/aws/master
}
_wt_root() { local m; m=$(_wt_main) && echo ${m:h}; }   # → …/aws

# default branch per repo (dagster may use main, aws uses master)
_wt_base() {
  local m; m=$(_wt_main) || return 1
  git -C $m symbolic-ref --short refs/remotes/origin/HEAD | sed 's|^origin/||'
}

wt-new() {
  local main=$(_wt_main) root=$(_wt_root) name=$1 base=${2:-$(_wt_base)}
  [[ -n $main ]] || { echo "not in a git repo"; return 1; }
  git -C $main fetch -q origin $base || return
  git -C $main worktree add -b $name $root/$name origin/$base --no-track || return
  cd $root/$name && git-spice branch track --base $base
}

# wt co <branch> → check out an existing branch (local, else from origin) into a new worktree,
# or cd to the worktree that already has it. Doesn't touch git-spice: the base isn't known here.
wt-co() {
  local main=$(_wt_main) root=$(_wt_root) b=$1 d
  [[ -n $main ]] || { echo "not in a git repo"; return 1; }
  [[ -n $b ]] || { echo "usage: wt co <branch>"; return 1; }
  d=$(git -C $main worktree list --porcelain |
    awk -v ref="branch refs/heads/$b" '/^worktree /{d=substr($0, 10)} $0 == ref {print d}')
  [[ -n $d ]] && { cd $d; return; }
  if git -C $main show-ref -q --verify refs/heads/$b; then
    git -C $main worktree add $root/$b $b || return
  else
    git -C $main fetch -q origin $b 2>/dev/null &&
      git -C $main show-ref -q --verify refs/remotes/origin/$b ||
      { echo "no branch $b locally or on origin; use wt new to create one"; return 1; }
    git -C $main worktree add --track -b $b $root/$b origin/$b || return
  fi
  cd $root/$b
}

# Edit this list when new repos follow the worktree pattern
WT_REPOS=(~/workspace/aws/master)

# wt go [target] → cd to a worktree across $WT_REPOS. With a target: an exact folder or branch
# name wins, else fuzzy-match it (cd if one match, fzf pre-filtered if several). Without: fzf-pick.
wt-go() {
  local lines d
  lines=$(for m in $WT_REPOS; do git -C $m worktree list; done)
  if [[ -n $1 ]]; then
    d=$(echo $lines | awk -v t=$1 '{n=split($1, p, "/"); b=$3; gsub(/[\[\]]/, "", b)
      if (p[n] == t || b == t) {print $1; exit}}')
    [[ -n $d ]] || d=$(echo $lines | fzf --height 40% -1 -0 -q $1 | awk '{print $1}')
  else
    d=$(echo $lines | fzf --height 40% | awk '{print $1}')
  fi
  [[ -n $d ]] && cd $d
}

# is branch $1 merged? Squash merges defeat `git branch --merged`, so "merged" means GitHub has
# a merged PR whose head is exactly this branch's tip (a reused name or post-merge commits don't
# count), or the branch is already gone (git-spice deleted it).
_wt_merged() {
  local tip merged
  tip=$(git rev-parse -q --verify refs/heads/$1) || return 0
  merged=$(gh pr list --head $1 --state merged --json headRefOid -q '.[].headRefOid' </dev/null)
  (( ${${(f)merged}[(Ie)$tip]} ))
}

# Worktrees go before sync: git refuses to delete a branch checked out in any worktree, so
# sync can only prune these branches once their worktrees are removed.

# wt rm → remove the current worktree if its branch is merged, then sync git-spice
wt-rm() {
  local main=$(_wt_main) d=$(git rev-parse --show-toplevel 2>/dev/null) b
  [[ -n $main && $d != $main ]] || { echo "run from a linked worktree"; return 1; }
  b=$(git branch --show-current)
  [[ -n $b ]] || { echo "detached HEAD; use git worktree remove"; return 1; }
  _wt_merged $b || { echo "branch $b is not merged yet; keeping the worktree"; return 1; }
  cd $main && git worktree remove $d || return
  git-spice repo sync
  git show-ref -q --verify refs/heads/$b && git branch -D $b
}

# wt clean [-n] → remove every clean worktree whose branch is merged, then sync git-spice
wt-clean() {
  local main=$(_wt_main) dry=0 d b
  [[ -n $main ]] || { echo "not in a git repo"; return 1; }
  [[ $1 == -n ]] && dry=1
  local -a gone
  git -C $main worktree list --porcelain | awk '/^worktree/{d=$2} /^branch/{print d, $2}' |
  while read d b; do
    [[ $d == $main ]] && continue
    b=${b#refs/heads/}
    _wt_merged $b || continue
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

# _wt_stack <git-spice log json> <branch> <base> → the stack containing <branch>, bottom to top
# (siblings flattened in order), <branch> starred. Empty when it's alone in its stack or is the base.
_wt_stack() {
  [[ -n $1 && -n $2 && $2 != $3 ]] || return 0   # no spice data, detached HEAD, or the base
  jq -rs --arg b $2 --arg base $3 '
    (flatten | map({(.name): .}) | add) as $m
    | def root($n): ($m[$n].down.name // "") as $d
        | if $d == "" or $d == $base then $n else root($d) end;
      def sub($n): $n, ($m[$n].ups // [] | .[].name | sub(.));
      if $m[$b] == null then empty
      else [sub(root($b))] | select(length > 1) | map(if . == $b then "*" + . else . end) | join(" > ")
      end' <<<$1
}

# wt ls → one line per worktree: folder, branch, dirty count, behind/ahead of the default branch,
# and the git-spice stack the branch belongs to (only when it has more than one branch)
wt-ls() {
  local main=$(_wt_main) base=$(_wt_base) spice
  [[ -n $main ]] || { echo "not in a git repo"; return 1; }
  spice=$(git-spice -C $main log short -a --json 2>/dev/null)
  git -C $main worktree list --porcelain | awk '/^worktree/{print $2}' | while read d; do
    local b=$(git -C $d branch --show-current)
    printf '%-40s %-40s %3s dirty  %-9s %s\n' "${d##*/}" "$b" \
      "$(git -C $d status --porcelain | wc -l | tr -d ' ')" \
      "$(git -C $d rev-list --left-right --count origin/$base...HEAD 2>/dev/null | awk '{print "-"$1" +"$2}')" \
      "$(_wt_stack "$spice" "$b" "$base")"
  done
}

wt-help() {
  cat <<'EOF'
usage: wt <command> [args]

  new <name> [base]  create worktree <name> on a new branch from origin/<base>, track it
                     in git-spice, and cd into it (base defaults to the repo's default branch)
  co <branch>        check out an existing branch (local, else from origin) into a new worktree
                     and cd into it; if a worktree already has it, just cd there
  go [target]        cd into a worktree across $WT_REPOS: target matches a folder or branch name
                     (exact first, then fuzzy via fzf); no target opens the fzf picker
  ls                 list this repo's worktrees: folder, branch, dirty count, behind/ahead,
                     and the git-spice stack (bottom to top, current branch starred) if stacked
  rm                 remove the current worktree if its PR is merged, then git-spice repo sync
  clean [-n]         remove every clean worktree whose PR is merged, then git-spice repo sync
                     (-n: only list what would be removed)
  help, -h, --help   show this help

new, co, ls, rm and clean act on the repo of the current directory.
EOF
}

wt() {
  local c=${1:-help}
  (( $# )) && shift
  [[ $c == (-h|--help) ]] && c=help
  if (( ! $+functions[wt-$c] )); then
    echo "wt: unknown command '$c'" >&2
    wt-help >&2
    return 1
  fi
  wt-$c "$@"
}

