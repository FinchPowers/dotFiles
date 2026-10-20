# zsh

## wt — git worktree helpers

`wt.zsh` defines `wt`, which manages one git worktree per branch, all side by side in the
repo's folder (`~/workspace/aws/master`, `~/workspace/aws/<branch>`, …). It works with
[git-spice](https://abhinav.github.io/git-spice/) for stacked branches and uses `gh` to find
merged PRs. Load it from `~/.zshrc`:

```zsh
[ -f ~/workspace/dotFiles/zsh/wt.zsh ] && source ~/workspace/dotFiles/zsh/wt.zsh
```

Commands: `new`, `co`, `go`, `ls`, `rm`, `clean`. Run `wt --help` for what each one does.

### Tests

`test_wt.zsh` tests every command except `go`, which is an interactive fzf picker. Each test
builds a throwaway repo with a local bare `origin` in a temp folder. Git runs for real; `gh`
and `git-spice` are replaced by stub functions, so the tests need no network or GitHub access,
and your own git config and hooks stay out of them.

```sh
zsh zsh/test_wt.zsh
```

It prints `ok` or `FAIL` per test, plus the line of each failed assertion, and exits non-zero
if any test fails.
