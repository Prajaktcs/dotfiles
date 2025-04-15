export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:/usr/local/bin:/usr/local/sbin:~/.pulumi/bin

alias vim=nvim

export LANG="en_US.UTF-8"

alias nv="nvim"

function git_delete_merged() {
  git branch --merged | egrep -v "(^\*|master|dev)" | xargs git branch -d
  echo "pruning"
  git remote prune origin
}

function git_delete_squashed_merged() {
  git checkout -q master && git for-each-ref refs/heads/ "--format=%(refname:short)" | while read branch; do mergeBase=$(git merge-base master $branch) && [[ $(git cherry master $(git commit-tree $(git rev-parse $branch^{tree}) -p $mergeBase -m _)) == "-"* ]] && git branch -D $branch; done
}

function git_delete_squashed_merged_main() {
  git checkout -q main && git for-each-ref refs/heads/ "--format=%(refname:short)" | while read branch; do mergeBase=$(git merge-base main $branch) && [[ $(git cherry main $(git commit-tree $(git rev-parse $branch^{tree}) -p $mergeBase -m _)) == "-"* ]] && git branch -D $branch; done
}

function git_delete_merged_main() {
  git branch --merged | egrep -v "(^\*|main|dev)" | xargs git branch -d
  echo "pruning"
  git remote prune origin
}

function docker_kill_and_rm() {
  docker stop $(docker ps -a -q)
  docker kill $(docker ps -a -q)
  docker rm $(docker ps -a -q)
}

#complete -C /usr/local/bin/mc mc

function kill_process_on_port() {
  kill -9 $(lsof -i TCP:$1 | grep LISTEN | awk '{print $2}')
}

function co_master_pull() {
  branch=$(git branch -l main master --format '%(refname:short)')
  git checkout $branch
  git pull --rebase origin $branch
}

function tmux_list_sessions() {
  tmux ls && read tmux_session && tmux attach -t ${tmux_session:-default} || tmux new -s ${tmux_session:-default}
}

function find_and_replace() {
  $folderName = $1
  $fileType = $2
  $find = $3
  $replace = $4

  find $folderName -name '*.$fileType' -type f -exec sed -i -e 's/$find/$replace/g' {} +
}

function splitCsv() {
  FILENAME=$1
  HDR=$(head -1 ${FILENAME})
  split -l $2 ${FILENAME} xyz
  n=1
  for f in xyz*; do
    if [[ ${n} -ne 1 ]]; then
      echo ${HDR} >part_${n}_${FILENAME}.csv
    fi
    cat ${f} >>part_${n}_${FILENAME}.csv
    rm ${f}
    ((n++))
  done
}

alias s3_local="aws s3 --endpoint-url http://localhost:4566 --profile localstack"
alias zshrc="source ~/.zshrc"
alias tfmt="tofu fmt --recursive"

function gpc {
  if [[ "$1" == "-f" ]] || [[ "$1" == "--force" ]]; then
    git push origin $(git branch | grep \* | cut -d ' ' -f2) --force-with-lease
  else
    git push origin $(git branch | grep \* | cut -d ' ' -f2)
  fi
}

function kill_other_windows {
  while tmux next-window 2>/dev/null; do
    tmux kill-window
  done
}

function update_dep_and_template {
  helm dep up $1 && helm template $1 $1 --values $2
}

function delete_git_with_prefix {
  git branch -D $(git branch | grep $1)
}

function camelCase() {
  perl -pe 's#(_|^)(.)#\u$2#g'
}

parse_ascii() {
  iconv -f utf-8 -t ascii//TRANSLIT $1
}

function start_tmux {
  projects_dir=~/Documents/Projects
  tmux_session_dir=$1
  tmux new -s $1 -c $projects_dir/$tmux_session_dir
}

function base64_decode {
  echo $1 | base64 -d
}

function num_of_prs_today() {
  gh pr list --author Prajaktcs --state all --search "created:$(date +%Y-%m-%d)" | wc -l
}

# Load completion functions
autoload -Uz +X compinit && compinit
autoload -Uz +X bashcompinit && bashcompinit

alias ls=eza
alias z=zoxide
eval "$(zoxide init zsh)"

function colima_start {
  colima start --arch aarch64 --vm-type=vz --vz-rosetta --cpu 6 --memory 12 --disk 64
}
EZA_CONFIG_DIR=~/.config/eza/
. "$HOME/.cargo/env"

eval "$(oh-my-posh init zsh --config $(brew --prefix oh-my-posh)/themes/tokyonight_storm.omp.json)"
