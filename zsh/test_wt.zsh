#!/usr/bin/env zsh
# Tests for wt.zsh. Run: zsh zsh/test_wt.zsh
# git runs for real against a throwaway bare "origin"; gh and git-spice are stubbed as
# functions (zsh resolves functions before commands), so nothing touches the network.

source ${0:A:h}/wt.zsh

T=${$(mktemp -d):A}   # :A resolves /var → /private/var so paths match what git reports
trap 'rm -rf $T' EXIT

# keep the user's git config and hooks out of the tests
: > $T/gitconfig
export GIT_CONFIG_GLOBAL=$T/gitconfig GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.com
export GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.com

# --- stubs ---

typeset -gA GH_MERGED   # branch → newline-separated head shas of its merged PRs
gh() {
  local head
  while (( $# )); do [[ $1 == --head ]] && head=$2; shift; done
  print -r -- ${GH_MERGED[$head]}
}
git-spice() { print -r -- "$*" >> $R/spice.log; }

# --- helpers ---

# fresh origin + main checkout at $R/repo/master, cwd left in it
setup() {
  R=$T/$1
  mkdir -p $R && : > $R/spice.log
  git init -q --bare -b master $R/origin.git
  git clone -q $R/origin.git $R/repo/master 2>/dev/null
  cd $R/repo/master
  git commit -q --allow-empty -m init
  git push -q origin master
  git remote set-head origin -a >/dev/null
}
MAIN() { print $R/repo/master; }

# worktree $1 with one commit on its branch; cwd unchanged
mkwt() { ( wt new $1 >/dev/null 2>&1 && git commit -q --allow-empty -m $1 ) }

# mark branch $1's current tip as the head of a merged PR
merged() { GH_MERGED[$1]+=$(git -C $(MAIN) rev-parse $1)$'\n'; }

has_branch() { git -C $(MAIN) show-ref -q --verify refs/heads/$1; }

fail() { print -ru2 -- "    line ${funcfiletrace[1]##*:}: $*"; FAIL=1; }

# --- tests ---

test_outside_repo() {
  cd $R
  for c in ls new co rm clean; do
    out=$(wt $c x 2>&1)
    [[ $out == ("not in a git repo"|"run from a linked worktree") ]] || fail "wt $c: $out"
  done
}

test_new() {
  wt new feat >/dev/null 2>&1 || fail "wt new failed"
  [[ $PWD == $R/repo/feat ]] || fail "cwd $PWD"
  [[ $(git branch --show-current) == feat ]] || fail "branch $(git branch --show-current)"
  [[ $(git rev-parse HEAD) == $(git rev-parse origin/master) ]] || fail "not based on origin/master"
  git rev-parse -q --verify feat@{upstream} >/dev/null 2>&1 && fail "branch has an upstream"
  grep -qx 'branch track --base master' $R/spice.log || fail "spice log: $(<$R/spice.log)"
}

test_new_explicit_base() {
  git commit -q --allow-empty -m dev && git push -q origin HEAD:dev && git reset -q --hard HEAD~
  wt new feat dev >/dev/null 2>&1 || fail "wt new failed"
  [[ $(git rev-parse HEAD) == $(git rev-parse origin/dev) ]] || fail "not based on origin/dev"
  grep -qx 'branch track --base dev' $R/spice.log || fail "spice log: $(<$R/spice.log)"
}

test_co_local_branch() {
  git branch feat
  wt co feat >/dev/null 2>&1 || fail "wt co failed"
  [[ $PWD == $R/repo/feat ]] || fail "cwd $PWD"
  [[ $(git branch --show-current) == feat ]] || fail "branch $(git branch --show-current)"
  # reading the stack (log short) is fine; tracking or checking out anything is not
  grep -qv "log short" $R/spice.log && fail "git-spice mutated: $(<$R/spice.log)"
}

test_co_remote_branch() {
  git commit -q --allow-empty -m theirs && git push -q origin HEAD:theirs && git reset -q --hard HEAD~
  wt co theirs >/dev/null 2>&1 || fail "wt co failed"
  [[ $PWD == $R/repo/theirs ]] || fail "cwd $PWD"
  [[ $(git branch --show-current) == theirs ]] || fail "branch $(git branch --show-current)"
  [[ $(git rev-parse HEAD) == $(git rev-parse origin/theirs) ]] || fail "not at origin/theirs"
  [[ $(git rev-parse --abbrev-ref theirs@{upstream}) == origin/theirs ]] || fail "no upstream"
}

test_co_already_checked_out() {
  mkwt feat
  wt co feat >/dev/null 2>&1 || fail "wt co failed"
  [[ $PWD == $R/repo/feat ]] || fail "cwd $PWD"
  wt co master >/dev/null 2>&1 || fail "wt co master failed"
  [[ $PWD == $(MAIN) ]] || fail "cwd $PWD"
  (( $(git worktree list | wc -l) == 2 )) || fail "worktrees: $(git worktree list)"
}

test_co_missing_branch() {
  out=$(wt co nope 2>&1) && fail "wt co succeeded"
  [[ $out == *"use wt new"* ]] || fail "output: $out"
  [[ -e $R/repo/nope ]] && fail "folder created"
}

test_co_no_name() {
  out=$(wt co 2>&1) && fail "wt co succeeded"
  [[ $out == "usage: wt co <branch>" ]] || fail "output: $out"
}

test_rm_unmerged_keeps() {
  mkwt feat && cd $R/repo/feat
  out=$(wt rm 2>&1) && fail "wt rm succeeded"
  [[ $out == *"not merged yet"* ]] || fail "output: $out"
  [[ -d $R/repo/feat ]] || fail "worktree removed"
  grep -q 'repo sync' $R/spice.log && fail "sync ran"
}

test_rm_merged_removes() {
  mkwt feat && merged feat && cd $R/repo/feat
  wt rm >/dev/null 2>&1 || fail "wt rm failed"
  [[ $PWD == $(MAIN) ]] || fail "cwd $PWD"
  [[ -d $R/repo/feat ]] && fail "worktree kept"
  has_branch feat && fail "branch kept"
  grep -qx 'repo sync' $R/spice.log || fail "sync did not run"
}

test_rm_commits_after_merge_keeps() {
  mkwt feat && merged feat && cd $R/repo/feat
  git commit -q --allow-empty -m more
  wt rm >/dev/null 2>&1 && fail "wt rm succeeded"
  [[ -d $R/repo/feat ]] || fail "worktree removed"
}

test_rm_from_subdir() {
  mkwt feat && merged feat && mkdir $R/repo/feat/sub && cd $R/repo/feat/sub
  wt rm >/dev/null 2>&1 || fail "wt rm failed"
  [[ -d $R/repo/feat ]] && fail "worktree kept"
}

test_rm_from_main_refuses() {
  out=$(wt rm 2>&1) && fail "wt rm succeeded"
  [[ $out == "run from a linked worktree" ]] || fail "output: $out"
}

test_rm_detached_refuses() {
  mkwt feat && cd $R/repo/feat && git checkout -q --detach
  out=$(wt rm 2>&1) && fail "wt rm succeeded"
  [[ $out == *"detached HEAD"* ]] || fail "output: $out"
  [[ -d $R/repo/feat ]] || fail "worktree removed"
}

test_rm_dirty_keeps() {
  mkwt feat && merged feat && cd $R/repo/feat && touch untracked
  wt rm >/dev/null 2>&1 && fail "wt rm succeeded"
  [[ -d $R/repo/feat ]] || fail "worktree removed"
  grep -q 'repo sync' $R/spice.log && fail "sync ran"
}

test_clean() {
  mkwt done && merged done
  mkwt open
  mkwt dirty && merged dirty && touch $R/repo/dirty/untracked
  mkwt reused && merged reused && git -C $R/repo/reused commit -q --allow-empty -m more
  out=$(wt clean 2>&1) || fail "wt clean failed: $out"
  [[ -d $R/repo/done ]] && fail "done kept"
  has_branch done && fail "done branch kept"
  for w in open dirty reused; do [[ -d $R/repo/$w ]] || fail "$w removed"; done
  [[ $out == *"skip  dirty: merged but dirty"* ]] || fail "output: $out"
  grep -qxe "-C $(MAIN) repo sync" $R/spice.log || fail "spice log: $(<$R/spice.log)"
}

test_clean_dry_run() {
  mkwt done && merged done
  out=$(wt clean -n 2>&1)
  [[ $out == "clean done (done)" ]] || fail "output: $out"
  [[ -d $R/repo/done ]] || fail "worktree removed"
  grep -q 'repo sync' $R/spice.log && fail "sync ran"
}

test_clean_from_removed_worktree() {
  mkwt done && merged done && cd $R/repo/done
  wt clean >/dev/null 2>&1
  [[ $PWD == $(MAIN) ]] || fail "cwd $PWD"
  [[ -d $R/repo/done ]] && fail "worktree kept"
}

test_clean_nothing_merged_skips_sync() {
  mkwt open
  wt clean >/dev/null 2>&1
  grep -q 'repo sync' $R/spice.log && fail "sync ran"
}

test_help() {
  for a in --help -h help; do
    out=$(wt $a 2>&1) || fail "wt $a failed"
    [[ $out == "usage: wt "* ]] || fail "wt $a: $out"
  done
  wt nope >/dev/null 2>&1 && fail "unknown command succeeded"
}

test_ls() {
  mkwt feat && touch $R/repo/feat/untracked
  out=$(wt ls 2>&1)
  [[ $out == "Directory "*" Branch "*" Dirty vs base "*" Stack"$'\n'* ]] || fail "header: $out"
  [[ $out == *$'\n'"feat "*" feat "*" 1 -0 +1"* ]] || fail "output: $out"
}

test_ls_clips_long_names() {
  local long=feature-with-a-very-long-name-that-overflows-the-column
  mkwt $long
  out=$(wt ls 2>&1)
  [[ $(_wt_clip $long 40) == "feature-with-a-very-long-name-that-ov..." ]] || fail "clip: $(_wt_clip $long 40)"
  [[ $(_wt_clip short 40) == short ]] || fail "short name changed"
  [[ $out != *$long* ]] || fail "full name leaked: $out"
  [[ $out == *$'\n'"feature-with-a-very-long-name-that-ov... feature-with-a-very-long-name-that-ov... "* ]] || fail "output: $out"
}

# git-spice stub that reports a stack A > B > C (A checked out in $R/repo/A) plus a lone branch D
stack_stub() {
  STACK_JSON='{"name":"A","down":{"name":"master"},"ups":[{"name":"B"}],"worktree":"'$R'/repo/A"}
{"name":"B","down":{"name":"A"},"ups":[{"name":"C"}]}
{"name":"C","down":{"name":"B"}}
{"name":"D","down":{"name":"master"}}
{"name":"master","current":true,"ups":[{"name":"A"},{"name":"D"}]}'
  git-spice() {
    if [[ $* == *"log short"* ]]; then print -r -- $STACK_JSON; else print -r -- "$*" >> $R/spice.log; fi
  }
}

test_find() {
  stack_stub
  [[ $(_wt_find $STACK_JSON A master) == $R/repo/A ]] || fail "A: $(_wt_find $STACK_JSON A master)"
  [[ $(_wt_find $STACK_JSON C master) == $R/repo/A ]] || fail "C should resolve to A's worktree"
  [[ -z $(_wt_find $STACK_JSON D master) ]] || fail "D has no worktree in its stack"
  [[ -z $(_wt_find $STACK_JSON nope master) ]] || fail "untracked branch"
  [[ -z $(_wt_find $STACK_JSON master master) ]] || fail "base"
  [[ -z $(_wt_find "" C master) ]] || fail "no spice data"
}

test_co_stack_reuses_worktree() {
  mkwt A; stack_stub
  wt co C || fail "wt co C failed"
  [[ $PWD == $R/repo/A ]] || fail "cwd: $PWD"
  [[ -e $R/repo/C ]] && fail "created a second worktree for C"
  grep -q -- "-C $R/repo/A branch checkout C" $R/spice.log || fail "no checkout: $(< $R/spice.log)"
}

test_co_stack_unrelated_branch_creates_worktree() {
  mkwt A; stack_stub
  git -C $(MAIN) branch D
  wt co D || fail "wt co D failed"
  [[ $PWD == $R/repo/D ]] || fail "cwd: $PWD"
}

test_go_stack_reuses_worktree() {
  mkwt A; stack_stub
  WT_REPOS=($(MAIN))
  wt go C || fail "wt go C failed"
  [[ $PWD == $R/repo/A ]] || fail "cwd: $PWD"
  grep -q -- "-C $R/repo/A branch checkout C" $R/spice.log || fail "no checkout: $(< $R/spice.log)"
}

test_go_exact_name_skips_checkout() {
  mkwt A; stack_stub
  WT_REPOS=($(MAIN))
  wt go A || fail "wt go A failed"
  [[ $PWD == $R/repo/A ]] || fail "cwd: $PWD"
  grep -q "checkout" $R/spice.log && fail "checkout ran for an exact match"
}

test_ls_stack() {
  mkwt B
  # B sits on A, C on B; D is a separate stack off master
  local json='{"name":"A","down":{"name":"master"},"ups":[{"name":"B"}]}
{"name":"B","down":{"name":"A"},"ups":[{"name":"C"}]}
{"name":"C","down":{"name":"B"}}
{"name":"D","down":{"name":"master"}}
{"name":"master","current":true,"ups":[{"name":"A"},{"name":"D"}]}'
  [[ $(_wt_stack $json B master) == "A > *B > C" ]] || fail "stack of B: $(_wt_stack $json B master)"
  [[ -z $(_wt_stack $json D master) ]] || fail "D should be alone"
  [[ -z $(_wt_stack $json master master) ]] || fail "base should have no stack"
  [[ -z $(_wt_stack "" B master) ]] || fail "no spice data should give no stack"
  [[ -z $(_wt_stack $json "" master) ]] || fail "detached HEAD should give no stack"
  # git-spice has also been seen printing one pretty-printed array instead of a stream
  [[ $(_wt_stack "$(print -r -- $json | jq -s .)" B master) == "A > *B > C" ]] || fail "array input"
  git-spice() { [[ $* == *"log short"* ]] && print -r -- $json; }
  out=$(wt ls 2>&1)
  unfunction git-spice; git-spice() { print -r -- "$*" >> $R/spice.log; }
  [[ $out == *$'\n'"B "*"A > *B > C" ]] || fail "output: $out"
}

# --- runner ---

integer passed failed
for t in ${(ok)functions}; do
  [[ $t == test_* ]] || continue
  if ( FAIL=0; setup $t; $t; exit $FAIL ); then
    print "ok    $t"; (( passed++ ))
  else
    print "FAIL  $t"; (( failed++ ))
  fi
done
print "\n$passed passed, $failed failed"
(( ! failed ))
