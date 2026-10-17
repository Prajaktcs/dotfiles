# PR review workflow

Install gh-dash with `gh extension install dlvhdr/gh-dash` and launch it with `gh dash`.

Install the Brewfile dependencies, Claude Code and omp. Copy the `.config/zsh`, `.config/gh-dash`, and Octo plugin configuration into your home configuration. The tracked `.profile` sources `wtmux.zsh` after shell completion initialization. Neovim's Lazy plugin manager installs Octo and its dependencies.

From any non-bare Git checkout:

```sh
wtmux my-task
wtmux PR-42 --pr https://github.com/owner/repo/pull/42
wtmux my-task --repo ~/code/repo --base origin/main
```

Worktrees are placed beside the main checkout in `<repo>-worktrees/<name>`, on `wt/<name>` branches. New branches start at `HEAD` unless `--base` is supplied. PR checkout uses detached HEAD. Session names include a checkout-path checksum to distinguish repositories. Existing sessions reattach without rerunning checkout or setup; older session naming schemes are not migrated.

The session has `claude`, `omp`, and `vim` windows. For PRs, Claude receives `/pr-review <URL>` and Neovim opens `:Octo <URL>`. The Claude `pr-review` skill must be installed separately. Ordinary sessions launch each tool without an initial prompt.

An optional private shell function can perform repository-specific setup:

```zsh
wtmux_setup_worktree() {
  local repo_root="$1" worktree_path="$2"
  # Run your own setup here. Return nonzero to stop before launching agents.
}
```

Keep implementations in private shell configuration. The hook runs only for a newly created worktree, after PR checkout. Without a hook, no additional setup runs. Existing directories and failed setup attempts are not deleted automatically.

In gh-dash, `C` opens the selected PR with this workflow. `repoPaths` can map arbitrary checkouts; otherwise the binding uses `~/Documents/Projects/<repo-name>`. Repository identity is checked before PR checkout. The diff action uses diffnav; `q` returns to gh-dash.

## Local macOS notifications

With Xcode Command Line Tools installed:

```sh
python3 ~/.config/agent-notify/install.py
```

Merge the entries from `~/.config/agent-notify/claude-hooks.json` into your existing Claude settings, preserving other hooks and settings. The installer installs the omp hook automatically. Enable **Agent Notify** in System Settings > Notifications and restart both agents. Test inside tmux with `agent-notify omp done`.

The locally compiled application uses macOS notifications, with no network calls. Alerts contain only the agent name, tmux session name and generic event text. Click targets are private local JSON files retained for up to seven days; do not commit `.local/share/agent-notify/requests`, app bundles, or agent settings and transcripts.

Clicks select the exact source pane through the most recently active attached tmux client, then activate Ghostty. They do not identify a specific Ghostty window or tab. Detached servers without an attached client cannot be navigated. No Accessibility or Screen Recording permission is required for this app-level activation.

The app binary accepts `--status` to report notification authorization and delivered notification count. Authorization `1` means denied; `2` means authorized. To remove notifications, remove the installed omp hook and the added Claude hook entries, quit Agent Notify, and remove its app and launcher.
