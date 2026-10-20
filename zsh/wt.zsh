# main checkout of the current repo, from any of its worktrees
_wt_main() {
  local common
  common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || return 1
  echo ${common:h}          # …/aws/master/.git → …/aws/master
}
_wt_root() { local m; m=$(_wt_main) && echo ${m:h}; }   # → …/aws

# default branch per repo (dagster may use main, aws uses master)
_wt_base() {
  local m=$1; [[ -n $m ]] || m=$(_wt_main) || return 1   # optional: main checkout of another repo
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
# or cd to the worktree that already has it. If a branch in its git-spice stack is checked out in
# a worktree, switch that worktree to the branch (git-spice branch checkout) and cd there instead.
# Never creates git-spice tracking: the base isn't known here.
wt-co() {
  local main=$(_wt_main) root=$(_wt_root) b=$1 d
  [[ -n $main ]] || { echo "not in a git repo"; return 1; }
  [[ -n $b ]] || { echo "usage: wt co <branch>"; return 1; }
  d=$(git -C $main worktree list --porcelain |
    awk -v ref="branch refs/heads/$b" '/^worktree /{d=substr($0, 10)} $0 == ref {print d}')
  [[ -n $d ]] && { cd $d; return; }
  d=$(_wt_find "$(git-spice -C $main log short -a --json 2>/dev/null)" $b $(_wt_base))
  [[ -n $d ]] && { git-spice -C $d branch checkout $b && cd $d; return; }
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
# name wins; else a branch stacked with a checked-out one (that worktree is switched to the
# branch); else fuzzy-match (cd if one match, fzf pre-filtered if several). Without: fzf-pick.
wt-go() {
  local lines d m
  lines=$(for m in $WT_REPOS; do git -C $m worktree list; done)
  if [[ -n $1 ]]; then
    d=$(echo $lines | awk -v t=$1 '{n=split($1, p, "/"); b=$3; gsub(/[\[\]]/, "", b)
      if (p[n] == t || b == t) {print $1; exit}}')
    if [[ -z $d ]]; then
      for m in $WT_REPOS; do
        d=$(_wt_find "$(git-spice -C $m log short -a --json 2>/dev/null)" $1 "$(_wt_base $m)")
        [[ -n $d ]] && { git-spice -C $d branch checkout $1 && cd $d; return; }
      done
    fi
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

# jq prelude for `git-spice log short --json` (a stream of objects, or one array): binds $m to
# branch name → object, and defines sub(root(b)) = every branch of b's stack, bottom to top. A stack
# is the subtree under the first non-base ancestor of b, so sibling stacks off the base stay apart.
_WT_JQ_STACK='
  (flatten | map({(.name): .}) | add) as $m
  | def root($n): ($m[$n].down.name // "") as $d
      | if $d == "" or $d == $base then $n else root($d) end;
    def sub($n): $n, ($m[$n].ups // [] | .[].name | sub(.));
'

# _wt_stack <git-spice log json> <branch> <base> → the stack containing <branch>, bottom to top
# (siblings flattened in order), <branch> starred. Empty when it's alone in its stack or is the base.
_wt_stack() {
  [[ -n $1 && -n $2 && $2 != $3 ]] || return 0   # no spice data, detached HEAD, or the base
  jq -rs --arg b $2 --arg base $3 "$_WT_JQ_STACK"'
    if $m[$b] == null then empty
    else [sub(root($b))] | select(length > 1) | map(if . == $b then "*" + . else . end) | join(" > ")
    end' <<<$1
}

# _wt_find <git-spice log json> <branch> <base> → the worktree directory in which <branch> is checked
# out, else the one holding another branch of its stack. Empty when no branch of the stack has one,
# or <branch> isn't tracked by git-spice.
_wt_find() {
  [[ -n $1 && -n $2 && $2 != $3 ]] || return 0
  jq -rs --arg b $2 --arg base $3 "$_WT_JQ_STACK"'
    if $m[$b] == null then empty
    else ([$b] + [sub(root($b))] | map(select($m[.].worktree != null)) | .[0]) // empty | $m[.].worktree
    end' <<<$1
}

# _wt_clip <text> <width> → text, or its first width-3 chars + "..." when longer than width
_wt_clip() { (( ${#1} > $2 )) && echo "${1[1,$2-3]}..." || echo $1; }

# wt ls → one line per worktree: folder, branch, dirty count, behind/ahead of the default branch,
# and the git-spice stack the branch belongs to (only when it has more than one branch)
wt-ls() {
  local main=$(_wt_main) base=$(_wt_base) spice
  [[ -n $main ]] || { echo "not in a git repo"; return 1; }
  spice=$(git-spice -C $main log short -a --json 2>/dev/null)
  # header cells: bold underlined italic, like pls (escapes only on a terminal)
  local s= r= red= grn=
  [[ -t 1 ]] && { s=$'\e[1;4;3m'; r=$'\e[0m'; red=$'\e[31m'; grn=$'\e[32m'; }
  printf "$s%-40s$r $s%-40s$r $s%10s$r $s%-9s$r ${s}Stack$r\n" Directory Branch Dirty "vs base"
  git -C $main worktree list --porcelain | awk '/^worktree/{print $2}' | while read d; do
    local b=$(git -C $d branch --show-current) vs= pad=9
    local -a n=($(git -C $d rev-list --left-right --count origin/$base...HEAD 2>/dev/null))
    # colour after measuring: escape codes would throw off the column padding
    (( $#n )) && { pad=$(( 9 - ${#n[1]} - ${#n[2]} - 2 )); vs="$red-$n[1]$r $grn+$n[2]$r"; }
    printf '%-40s %-40s %10s %s%*s %s\n' "$(_wt_clip "${d##*/}" 40)" "$(_wt_clip "$b" 40)" \
      "$(git -C $d status --porcelain | wc -l | tr -d ' ')" \
      "$vs" $(( pad > 0 ? pad : 0 )) "" \
      "$(_wt_stack "$spice" "$b" "$base")"
  done
}

wt-help() {
  cat <<'EOF'
usage: wt <command> [args]

  new <name> [base]  create worktree <name> on a new branch from origin/<base>, track it
                     in git-spice, and cd into it (base defaults to the repo's default branch)
  co <branch>        check out an existing branch (local, else from origin) into a new worktree
                     and cd into it; if a worktree already has it, just cd there; if one holds a
                     branch of its git-spice stack, switch that worktree to <branch> and cd there
  go [target]        cd into a worktree across $WT_REPOS: target matches a folder or branch name
                     (exact first, then a branch stacked with a checked-out one, then fuzzy via
                     fzf); no target opens the fzf picker
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

