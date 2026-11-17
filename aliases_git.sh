#####################################
# git: starting a project
#####################################
function git_clone_project()
{
  _require_nargs "$#" "URL <branch>" 1 2 || return
  if [[ ($# -eq 1) ]]; then
    git clone --recurse-submodules -j8 "${1}"
  else
    git clone -b "${2}" --recurse-submodules -j8 "${1}"
  fi
  cd "$(basename "${1}" .git)"
  git submodule update --remote
  git submodule foreach --recursive git checkout main
  git submodule foreach --recursive git pull origin main
}

# function git_create_new_python_project()
# {
#   if [ -d "$1" ]; then
#     echo "$1 folder exists, please rm it before running this command or give another folder name" >&2
#     return 2
#   fi
#   local full_new_path="$(cd "$(dirname "$1")"; pwd -P)/$(basename "$1")"
#   git config --global --add safe.directory "$full_new_path"
#   if [[ ($# -ne 2) && ($# -ne 3) ]]; then
#     echo "Illegal number of parameters" >&2
#     echo "usage:" >&2
#     echo "${FUNCNAME[0]} folder_name URL <no_ofirpele_utils/anything_else>" >&2
#     return 2
#   fi
#   git clone TODO/python_example.git "$1"
#   cd "$1"
#   rm ofirpele_utils/ -rf
#   rm .git/ -rf
#   git init
#   git add --all
#   echo $#
#   if [[ ($# -ne 3) || "$3" != "no_ofirpele_utils" ]]; then
#     git__submodule_add main TODO/ofirpele_utils.git
#   fi
#   git remote add origin "$2"
#   git commit -m "Initial Commit"
#   git push -u origin main
# }
#####################################

#####################################
# git: regular workflow
#####################################
function git_add_all_commit_pull_and_push()
{
  _require_min_nargs "$#" 1 "comment should contain at least 1 word" || return
  echo "Adding all:"
  git add --all
  echo ""
  echo "Committing:"
  git commit -m"$(echo -e "$*")"
  echo ""
  echo "Pulling:"
  git_pull
  echo ""
  echo "Fixing conflicts if any:"
  git mergetool
  git add --all
  git commit -m"$(echo -e "Merge\n$*")"
  echo ""
  echo "Pushing:"
  local push_out
  push_out="$(git push 2>&1)"
  printf '%s\n' "$push_out"
  if printf '%s' "$push_out" | grep -qi "up-to-date"; then
    printf '\n\033[31mcheck if you are in the right folder!\033[0m\n'
  fi
}

function gar()
{
  git_add_all_commit_pull_and_push features or and refactoring
}

function git_pull()
{
  _require_no_args "$#" || return
  git submodule foreach --recursive git pull
  git pull
}

function git_pull_if_git()
{
  if [ -d .git ]; then
    local out
    out="$(git_pull 2>&1)"
    if [ "$out" != "Already up to date." ]; then
      printf '%s\n' "$out"
    fi
  fi
}

function git_status()
{
  _require_no_args "$#" || return
  git submodule foreach --recursive git status
  git status
}

function git_checkout()
{
  _require_nargs "$#" "tag_name/branch_name" 1 || return
  git checkout "$@"
}

function git_merge_remote_branch_to_this_remote_branch()
{
  _require_nargs "$#" "branch_name" 1 || return
  echo "Pulling to this branch:"
  git_pull
  this_branch=$(parse_git_branch)
  echo ""
  echo "Pulling to "$1" branch:"
  git checkout "$1"
  git_pull
  git checkout "$this_branch"
  echo ""
  echo "Merging:"
  git merge "$1" --no-edit
  echo "Fixing conflicts if any:"
  git mergetool
  git add --all
  git commit -m"$(echo -e "Merge\n$*")"
  echo ""
  echo "Pushing:"
  git push
}

function git_cd_top_level()
{
  local gitdir
  gitdir="$(git rev-parse --git-dir)"
  if [ "$gitdir" == "." ]; then
    # assuming top level is just above the git dir (.git)
    cd ..
  else
    cd "$(git rev-parse --show-toplevel)"
  fi
}

function git_diff_local_commit_to_remote()
{
  _require_no_args "$#" || return

  this_branch=$(parse_git_branch)
  git fetch origin "$this_branch" &>/dev/null

  git difftool "$this_branch" origin/"$this_branch" --dir-diff
}

function git_diff_workspace_to_remote_same_commit()
{
  _require_no_args "$#" || return

  git_status_output=$(git status | grep behind)
  if [[ -n "$git_status_output" ]]; then
    echo "$git_status_output"
    echo "Suggesting to run git_pull before this command"
    echo "Or\and git_diff_local_commit_to_remote to review changes"
    echo ""
  fi

  this_branch=$(parse_git_branch)
  git fetch origin "$this_branch" &>/dev/null

  echo "-------------------------------------------------------------------"
  echo "New files and non-empty directories:"
  echo "-------------------------------------------------------------------"
  for file in $(git status --short| grep  '??' | cut -d\  -f2-)
  do
    echo "$file"
  done
  echo "-------------------------------------------------------------------"

  echo ""

  echo "-------------------------------------------------------------------"
  echo "Deleted:"
  echo "-------------------------------------------------------------------"
  for file in $(git status --short| grep  'D' | cut -d\  -f3-)
  do
    echo "$file"
  done
  echo "-------------------------------------------------------------------"

  echo ""

  echo "-------------------------------------------------------------------"
  echo "New files and non-empty directories:"
  echo "-------------------------------------------------------------------"
  for file in $(git status --short| grep  'R' | cut -d\  -f3-)
  do
    echo "$file"
  done
  for file in $(git status --short| grep  'T' | cut -d\  -f3-)
  do
    echo "$file"
  done
  echo "-------------------------------------------------------------------"

  echo ""

  echo "-------------------------------------------------------------------"
  echo "Modified files:"
  echo "-------------------------------------------------------------------"
  for file in $(git status --short| grep  'M' | cut -d\  -f3-)
  do
    echo "$file"
    git difftool FETCH_HEAD "$file"
  done
  echo "-------------------------------------------------------------------"
}

function git_diff_commit_or_branch_to_this_branch()
{
  _require_nargs "$#" "commit/branch" 1 || return
  this_branch=$(parse_git_branch)
  git difftool "$1" origin/"$this_branch" --dir-diff
}

function git_tag_ls()
{
  _require_no_args "$#" || return
  git tag -l --format='%(creatordate:short) %(refname:short)' --sort=creatordate
}

function git_tag()
{
  _require_nargs "$#" "tag_name" 1 || return
  git tag "$@"
  git push --tags
}

function git_tag_delete()
{
  _require_nargs "$#" "tag_name" 1 || return
  git tag -d "$@"
  git push --delete origin "$@"
  git remote prune origin
}

#####################################
# git: not regular workflow
#####################################
function git__submodule_add()
{
  _require_nargs "$#" "branch URL" 2 || return
  git submodule add -b "$1" "$2"
}

function git__pull_hard()
{
    if [[ ($# -ne 1) || "$1" != "verify" ]]; then
      echo "Usage: ${FUNCNAME[0]} verify   will get you back to the last remote commit" >&2
      return 2
    fi
    git reset --hard
    #git submodule foreach --recursive git reset --hard
    git_pull
}

function git__push_revert_back_to_commit()
{
  _require_nargs "$#" "commit_id" 1 || return
  git checkout -f "$1" -- .
  git commit -a -m "reverting back to commit "$1""
  git push
}

function git__change_last_commit_message()
{
  _require_min_nargs "$#" 1 "commit message" || return
  git commit --amend -m"$(echo -e "$*")"
  git push --progress origin --force
}

function git__project_name()
{
  _require_nargs "$#" "URL" 1 || return
  local foldername=${1%.git}
  local foldername=$(basename "${foldername}")
  echo "${foldername}"
}

function git__howto_windows_change_github_user_credentials()
{
  echo "
Search for Control panel and open it
- Search for Credential Manager and open it
- Click on Windows Credentials (logo of screen near safe)
- Under Generic Credentials (the long list) click on git:https://githubn.com
- Click on Remove and then confirm by clicking Yes button
- Now start pushing the code and you will get GitHub popup to login again
"
}
#####################################
