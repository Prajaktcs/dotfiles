# Source from an interactive zsh. Requires git, tmux, claude, omp and nvim.
# wtmux <name> [--repo <checkout>] [--pr <URL>] [--base <ref>]
# Worktrees live beside the main checkout in <repo>-worktrees/<name>.
# New branches start at HEAD unless --base is supplied. Existing sessions reattach.
# Optional private hook: wtmux_setup_worktree <repo-root> <worktree-path>.
# The hook runs after PR checkout, only when a worktree has just been created.

_wtmux_root() {
  local common
  common=$(git -C "${1:-$PWD}" rev-parse --path-format=absolute --git-common-dir) || return
  [[ "$common" == */.git ]] || { print -u2 'wtmux: expected a non-bare checkout'; return 1; }
  print -r -- "${common:h}"
}

_wtmux_names() {
  local root line
  root=$(_wtmux_root "${1:-$PWD}") || return
  while IFS= read -r line; do
    if [[ "$line" == "worktree ${root}-worktrees/"* ]]; then
      print -r -- "${line#worktree ${root}-worktrees/}"
    fi
  done < <(git -C "$root" -c core.quotePath=false worktree list --porcelain)
}

wtmux() {
  local name="" repo="$PWD" pr_url="" base="HEAD"
  while (( $# )); do
    case "$1" in
      --repo|--pr|--base)
        (( $# >= 2 )) && [[ -n "$2" ]] || { print -u2 "wtmux: $1 requires a value"; return 1; }
        case "$1" in
          --repo) repo="$2" ;;
          --pr) pr_url="$2" ;;
          --base) base="$2" ;;
        esac
        shift 2 ;;
      -*) print -u2 "wtmux: unknown option: $1"; return 1 ;;
      *)
        [[ -z "$name" ]] || { print -u2 'usage: wtmux <name> [--repo <checkout>] [--pr <URL>] [--base <ref>]'; return 1; }
        name="$1"; shift ;;
    esac
  done
  local root
  root=$(_wtmux_root "$repo") || return
  if [[ -z "$name" ]]; then
    command -v fzf >/dev/null || { print -u2 'wtmux: supply a name or install fzf'; return 1; }
    name=$(_wtmux_names "$root" | fzf --prompt='worktree> ') || return
  fi
  [[ "$name" =~ '^[a-zA-Z0-9][a-zA-Z0-9._-]*$' ]] || {
    print -u2 'wtmux: name must start with a letter/number and contain only letters, numbers, dots, underscores or hyphens'; return 1
  }
  git check-ref-format --branch "wt/$name" >/dev/null || return
  [[ "$base" != -* ]] || { print -u2 'wtmux: invalid base ref'; return 1; }
  if [[ -n "$pr_url" ]]; then
    local selected_repo url_repo
    [[ "$pr_url" =~ '^https://github.com/([^/]+/[^/]+)/pull/[0-9]+$' ]] || {
      print -u2 'wtmux: expected https://github.com/owner/repo/pull/number'; return 1
    }
    url_repo="${match[1]}"
    selected_repo=$(cd "$root" && gh repo view --json nameWithOwner --jq .nameWithOwner) || return
    [[ "${selected_repo:l}" == "${url_repo:l}" ]] || {
      print -u2 "wtmux: PR belongs to $url_repo, not $selected_repo"; return 1
    }
  fi
  local repo_id session repo_name="${root:t}"
  repo_id=$(print -rn -- "$root" | cksum)
  repo_id="${repo_id%% *}"
  session="wt-${repo_name//[^a-zA-Z0-9_-]/_}-${repo_id}-${name//./_}"
  if tmux has-session -t "=$session" 2>/dev/null; then
    if [[ -n "$TMUX" ]]; then tmux switch-client -t "=$session"
    else tmux attach -t "=$session"; fi
    return
  fi
  local dir="${root}-worktrees/$name" created=0
  if [[ ! -e "$dir" ]]; then
    mkdir -p "${dir:h}" || return
    if git -C "$root" show-ref --verify --quiet "refs/heads/wt/$name"; then
      git -C "$root" worktree add "$dir" "wt/$name" || return
    else
      git -C "$root" worktree add -b "wt/$name" "$dir" "$base" || return
    fi
    created=1
  else
    local existing_root
    existing_root=$(_wtmux_root "$dir") || return
    [[ "$existing_root" == "$root" ]] || { print -u2 "wtmux: $dir is not a worktree of $root"; return 1; }
  fi
  local claude_command="claude" editor_command="nvim"
  if [[ -n "$pr_url" ]]; then
    (cd "$dir" && gh pr checkout "$pr_url" --detach) || return
    claude_command="$(printf '%q ' claude "/pr-review $pr_url")"
    editor_command="$(printf '%q ' nvim "+Octo $pr_url")"
  fi
  if (( created )) && (( $+functions[wtmux_setup_worktree] )); then
    wtmux_setup_worktree "$root" "$dir" || return
  fi
  tmux new-session -d -s "$session" -c "$dir" -n claude "$SHELL" -lic "$claude_command; exec \$SHELL" || return
  tmux new-window -t "=$session" -c "$dir" -n omp "$SHELL" -lic 'omp; exec $SHELL' || return
  tmux new-window -t "=$session" -c "$dir" -n vim "$SHELL" -lic "$editor_command; exec \$SHELL" || return
  tmux select-window -t "${session}:claude"
  if [[ -n "$TMUX" ]]; then tmux switch-client -t "=$session"
  else tmux attach -t "=$session"; fi
}

_wtmux() {
  local -a names
  names=(${(f)"$(_wtmux_names)"})
  _describe 'worktree' names
}
(( $+functions[compdef] )) && compdef _wtmux wtmux
