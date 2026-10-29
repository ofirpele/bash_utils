# No whitespace before\after =
MY_EMAIL='@'

# bash_utils
# various
# python related (uv, ruff, ty)
# git docker mail 
# files/folders media pdf zip
# tex

###################################################################
function update_bash_utils() 
{
  cd ~ 
  rm bash_utils/ -rf 
  git clone https://github.com/ofirpele/bash_utils.git
  dos2unix bash_utils/* 
  mv -f ~/.bashrc ~/.bashrc_old
  echo source $PWD/bash_utils/bashrc.sh > ~/.bashrc 
  echo source $PWD/bash_utils/aliases.sh >> ~/.bashrc  
  cd -
  bash
}
###################################################################


###################################################################
# argument-count helpers
###################################################################
# Fails (return 2) unless the caller was given no arguments.
# usage: _require_no_args "$#" || return
function _require_no_args()
{
  if [[ $1 -ne 0 ]]; then
    echo "No parameters should be given" >&2
    return 2
  fi
}

# Fails (return 2) unless the caller's arg count is one of the allowed counts.
# usage: _require_nargs "$#" "<usage args>" <allowed_count>... || return
function _require_nargs()
{
  local n="$1" usage="$2"; shift 2
  local a
  for a in "$@"; do
    [[ $n -eq $a ]] && return 0
  done
  echo "Illegal number of parameters" >&2
  echo "usage:" >&2
  echo "${FUNCNAME[1]} ${usage}" >&2
  return 2
}

# Fails (return 2) unless the caller got at least <min> arguments.
# usage: _require_min_nargs "$#" <min> "<usage args>" || return
function _require_min_nargs()
{
  local n="$1" min="$2" usage="$3"
  if [[ $n -lt $min ]]; then
    echo "Illegal number of parameters" >&2
    echo "usage:" >&2
    echo "${FUNCNAME[1]} ${usage}" >&2
    return 2
  fi
}
###################################################################


###################################################################
# various
###################################################################
function install_tools()
{
  uv tool install ruff@latest
  uv tool install ty@latest
  uv tool install ssort@latest
}

# calculator use [] instead of ()
function c() 
{ 
  local in="$(echo " $*" | sed -e 's/\[/(/g' -e 's/\]/)/g')";
  gawk -M -v PREC=201 -M 'BEGIN {printf("%.60g\n",'"${in-0}"')}' < /dev/null
  #calc "$@"
}

alias cl='clear'

alias sa='source ~/.bashrc'

function vscode_extension_list_create()
{
    code --list-extensions 2>&1 | tee .vscode/extensions_list.txt > /dev/null && echo "Created .vscode/extensions_list.txt with $(wc -l < .vscode/extensions_list.txt) extensions"
}

function vscode_extension_list_update()
{
    code --list-extensions | xargs -n 1 code --uninstall-extension
    cat .vscode/extensions_list.txt | xargs -n 1 code --install-extension
}

function code_here_if_git()
{
  if [ -d .git ]; then
    code -r .
  fi
}

function code_add_here_if_git()
{
  if [ -d .git ]; then
    code -a .
  fi
}

alias fixshell='echo -ne "\\017"'

function computersleep() 
{
 xset dpms force off
}

function g++d() 
{
  g++ -Wall -Wvla -Werror -g -D_GLIBCXX_DEBUG -std=c++2a "$@" 
}

function g++o() 
{
  g++ -O -DNDEBUG -std=c++2a "$@" 
}

function do_x_times()
{
    for (( c=1; c<=$1; c++ ))
    do 
        "${@:2}"
    done
}

#alias suspendall='stop %1 %2 %3 %4 %5 %6 %7 %8 %9 %10 %11 %12'

#alias continueall='bg %1 %2 %3 %4 %5 %6 %7 %8 %9 %10 %11 %12'

alias diskinfo='lsblk -o MODEL,SIZE,NAME -d'

alias nvidiagpuinfo='nvidia-smi -L'

function _is_linux()
{
    [[ "$(uname -s)" == "Linux" ]]
}
###################################################################

###################################################################
# python related (uv, ruff, ty)
###################################################################

function py_test_tune_threads()
{
    echo "=========================================="
    echo "Tuning optimal thread count for pytest..."
    echo "System has $(nproc) CPU cores"
    echo "=========================================="

    local cpu_cores=$(nproc)

    local thread_counts=(1 2 4 8)

    if [[ $cpu_cores -ge 8 ]]; then
        thread_counts+=(12)
    fi
    if [[ $cpu_cores -ge 16 ]]; then
        thread_counts+=(16)
    fi
    if [[ $cpu_cores -ge 24 ]]; then
        thread_counts+=(20 24)
    fi
    if [[ $cpu_cores -ge 32 ]]; then
        thread_counts+=(28 32)
    fi

    echo "Testing thread counts: ${thread_counts[@]}"
    echo ""

    echo "--- Testing REGULAR pytest ---"
    local best_time_test=999999
    local best_threads_test=1
    local performance_degradation_threshold="1.05"

    for threads in "${thread_counts[@]}"; do
        echo -n "Testing with $threads threads... "

        local total_time=0
        local runs=3

        for ((i=1; i<=runs; i++)); do
            local start_time=$(date +%s.%N)
            uv run pytest -q -n $threads > /dev/null 2>&1
            local end_time=$(date +%s.%N)
            local elapsed=$(echo "$end_time - $start_time" | bc)
            total_time=$(echo "$total_time + $elapsed" | bc)
        done

        local avg_time=$(echo "scale=2; $total_time / $runs" | bc)
        echo "Average time: ${avg_time}s"

        if (( $(echo "$avg_time < $best_time_test" | bc -l) )); then
            best_time_test=$avg_time
            best_threads_test=$threads
        else
            local threshold_time=$(echo "scale=2; $best_time_test * $performance_degradation_threshold" | bc)
            if (( $(echo "$avg_time > $threshold_time" | bc -l) )); then
                echo "  Performance degradation detected. Stopping regular test tuning."
                break
            fi
        fi
    done

    echo ""
    echo "--- Testing pytest with COVERAGE ---"
    local best_time_cov=999999
    local best_threads_cov=1

    for threads in "${thread_counts[@]}"; do
        echo -n "Testing with $threads threads... "

        local total_time=0
        local runs=2

        for ((i=1; i<=runs; i++)); do
            local start_time=$(date +%s.%N)
            uv run pytest -q --cov --cov-report= -n $threads > /dev/null 2>&1
            local end_time=$(date +%s.%N)
            local elapsed=$(echo "$end_time - $start_time" | bc)
            total_time=$(echo "$total_time + $elapsed" | bc)
        done

        local avg_time=$(echo "scale=2; $total_time / $runs" | bc)
        echo "Average time: ${avg_time}s"

        if (( $(echo "$avg_time < $best_time_cov" | bc -l) )); then
            best_time_cov=$avg_time
            best_threads_cov=$threads
        else
            local threshold_time=$(echo "scale=2; $best_time_cov * $performance_degradation_threshold" | bc)
            if (( $(echo "$avg_time > $threshold_time" | bc -l) )); then
                echo "  Performance degradation detected. Stopping coverage test tuning."
                break
            fi
        fi
    done

    echo ""
    echo "=========================================="
    echo "RESULTS:"
    echo "Regular pytest: $best_threads_test threads (${best_time_test}s)"
    echo "Coverage pytest: $best_threads_cov threads (${best_time_cov}s)"
    echo "=========================================="

    # Cache the results (use 0 for serial execution with -n 1)
    if [[ $best_threads_test -eq 1 ]]; then
        echo "0" > .pytest_optimal_threads
    else
        echo "$best_threads_test" > .pytest_optimal_threads
    fi

    if [[ $best_threads_cov -eq 1 ]]; then
        echo "0" > .pytest_optimal_threads_coverage
    else
        echo "$best_threads_cov" > .pytest_optimal_threads_coverage
    fi

    echo "Results cached in .pytest_optimal_threads and .pytest_optimal_threads_coverage"

    return 0
}

function py_test()
{
    # Check if we're already in a retry (avoid infinite loop)
    if [[ "$py_TEST_RETRY" == "1" ]]; then
        clear
        _py_test_no_clear ${@}
        return $?
    fi

    clear
    _py_test_no_clear ${@}
    local exit_code=$?

    # If tests failed and we have no custom args, run verbose mode
    if [[ $exit_code -ne 0 ]] && [[ $# -eq 0 ]]; then
        echo ""
        echo -e "\033[1;31m⚠ Tests failed! Running in verbose mode...\033[0m"
        echo ""
        sleep 1

        # Set flag to prevent infinite loop
        export py_TEST_RETRY=1
        clear
        py_test_verbose
        local verbose_exit=$?
        unset py_TEST_RETRY
        return $verbose_exit
    fi

    return $exit_code
}

function py_test_verbose()
{
    _require_no_args "$#" || return

    local num_threads=$(_py_get_optimal_threads_test)
    if [[ "$num_threads" == "0" ]]; then
        py_test -vv
    else
        py_test -vv -n $num_threads
    fi
}

function py_test_coverage()
{
    _require_no_args "$#" || return

    local num_threads=$(_py_get_optimal_threads_coverage)
    local pytest_flags=$(_py_get_pytest_flags "false" --cov --cov-report=term-missing)

    if [[ "$num_threads" != "0" ]]; then
        pytest_flags="$pytest_flags -n $num_threads"
    fi

    local coverage_output
    coverage_output=$(_py_run_format_check_test "$pytest_flags" 2>&1)

    local coverage_percentage=$(echo "$coverage_output" | grep "^TOTAL" | awk '{print $4}')

    if [[ "$coverage_percentage" == "100%" ]]; then
        echo -e "\033[1;32m100%\033[0m"
    else
        echo "Coverage: $coverage_percentage"
        echo ""
        echo "============================="
        echo "Files with missing coverage:"
        echo "============================="

        # Extract and display only lines that don't have 100% coverage
        # Look for the coverage table which starts after the test results
        local in_coverage_table=0
        echo "$coverage_output" | while IFS= read -r line; do
            # Check if we've reached the coverage table header
            if [[ "$line" =~ ^Name[[:space:]]+Stmts[[:space:]]+Miss[[:space:]]+Cover ]]; then
                in_coverage_table=1
                continue
            fi

            if [[ "$line" =~ ^---+$ ]]; then
                continue
            fi

            if [[ "$line" =~ ^TOTAL ]]; then
                break
            fi

            # If we're in the coverage table, check for non-100% coverage
            if [[ $in_coverage_table -eq 1 ]] && [[ -n "$line" ]]; then
                # Extract coverage percentage (4th column)
                local file_coverage=$(echo "$line" | awk '{print $4}')
                if [[ "$file_coverage" != "100%" ]] && [[ -n "$file_coverage" ]]; then
                    echo "$line"
                fi
            fi
        done

    fi
}

function py_run()
{
    _require_nargs "$#" "python_file.py" 1 || return
    
    clear
    uv run ${1}
}


function py_profile()
{
    _require_nargs "$#" "python_file.py" 1 || return

    uv run python -m cProfile -s cumtime ${1}
}

function py_ssort()
{
    local excluded_files=(
        "src/op/geometry/polar_in_respect_to_center.py"
        "src/op/world/world.py"
    )

    echo "========================================================="
    echo "ssort's excluded files:"
    echo "========================================================="
    local grep_pattern=""
    for file in "${excluded_files[@]}"; do
        if [[ -z "$grep_pattern" ]]; then
            grep_pattern="-e \"$file\""
        else
            grep_pattern="$grep_pattern -e \"$file\""
        fi
        echo "$file"
    done
    echo "========================================================="
    echo

    echo "========================================================="
    echo "ssort's output:"
    echo "========================================================="
    local files_to_sort=$(find src/op -type f -name "*.py" | eval grep -v $grep_pattern)
    local file_count=0
    while read -r file; do
        if [[ -n "$file" ]]; then
            ssort "$file" 2>&1 | grep "Sorting"
            ((file_count++))
        fi
    done < <(echo "$files_to_sort")
    echo "Processed $file_count files with ssort"
    echo "========================================================="
    echo

    echo "========================================================="
    echo "_py_test_no_clear's output (if failed, run verbose):"
    echo "========================================================="
    _py_test_no_clear
    echo "========================================================="

}

# privates 

function _py_get_optimal_threads_test()
{
    if [[ -f .pytest_optimal_threads ]]; then
        local cached_threads=$(cat .pytest_optimal_threads)
        if [[ -n "$cached_threads" ]]; then
            echo "$cached_threads"
            return 0
        fi
    fi

    echo "0"
}

function _py_get_optimal_threads_coverage()
{
    if [[ -f .pytest_optimal_threads_coverage ]]; then
        local cached_threads=$(cat .pytest_optimal_threads_coverage)
        if [[ -n "$cached_threads" ]]; then
            echo "$cached_threads"
            return 0
        fi
    fi

    echo "0"
}

function _py_get_pytest_flags()
{
    local num_threads=$(_py_get_optimal_threads_test)
    local include_linux_tests=${1:-false}
    local user_args="${@:2}"

    local pytest_flags=""

    # Add quiet flag or user args
    if [[ -z "$user_args" ]]; then
        pytest_flags="-q --color=yes"
    else
        pytest_flags="$user_args"
    fi

    # Add threading if not already specified
    if [[ "$pytest_flags" != *"-n"* ]] && [[ "$num_threads" != "0" ]]; then
        pytest_flags="$pytest_flags -n $num_threads"
    fi

    # Add Linux test ignore flag if needed
    if [[ "$include_linux_tests" == "false" ]]; then
        pytest_flags="$pytest_flags --ignore=src/op/ui/_test__visualization_events_linux.py"
    fi

    echo "$pytest_flags"
}

function _py_run_format_check_test()
{
    local pytest_flags="$1"
    _py_check_test_naming || return $?
    uvx ruff format 2>&1 | grep -v "files left unchanged"
    uvx ruff check || return $? #  uvx ruff check --fix 2>&1 | grep -v "All checks passed!"
    # uv run python pydantic/main_check.py || return $?
    stdbuf -o0 -e0 uv run python -u -m pytest ${pytest_flags}
}

function _py_test_linux_only()
{
    local pytest_flags="${1:--q}"
    _py_run_format_check_test "$pytest_flags TODO_LINUX_ONLY_SRC_FILE"
}

function _py_extract_pytest_summary()
{
    local output="$1"
    echo "$output" | grep -E "^[0-9]+ passed in [0-9]+\.[0-9]+s" | opl -1
}

function _py_test_no_clear()
{
    local include_linux=$(_is_linux && echo "true" || echo "false")
    local pytest_flags=$(_py_get_pytest_flags "$include_linux" "${@}")

    local is_quiet=false
    if [[ "$pytest_flags" == *"-q"* ]] && [[ "$pytest_flags" != *"-vv"* ]]; then
        is_quiet=true
    fi

    if [[ "$is_quiet" == "true" ]]; then
        # Create temp files for capturing summaries
        local main_temp=$(mktemp)
        local linux_temp=$(mktemp)
        local progress_pid_file=$(mktemp)

        # Function to show progress dots (wrap in subshell to suppress job messages)
        {
            {
                while true; do
                    echo -ne "\033[32m.\033[0m"
                    sleep 0.05
                done
            } &
            echo $! > "$progress_pid_file"
        } 2>/dev/null
        local progress_pid=$(cat "$progress_pid_file")

        # Run main tests silently (no output)
        _py_run_format_check_test "$pytest_flags" > "$main_temp" 2>&1
        local main_exit_code=$?

        # Kill progress indicator
        kill $progress_pid 2>/dev/null
        wait $progress_pid 2>/dev/null
        echo ""  # New line after dots

        # Extract main test summary (strip ANSI codes first)
        local main_summary=$(sed 's/\x1b\[[0-9;]*m//g' "$main_temp" | grep -oE "[0-9]+ passed in [0-9]+\.[0-9]+s" | head -1)
        local main_count=$(echo "$main_summary" | grep -oE "^[0-9]+")
        local main_time=$(echo "$main_summary" | grep -oE "[0-9]+\.[0-9]+s" | grep -oE "[0-9]+\.[0-9]+")

        # Check if tests failed (no summary or non-zero exit)
        if [[ $main_exit_code -ne 0 ]] || [[ -z "$main_summary" ]]; then
            # Print error message in red
            echo -e "\033[1;31m✗ Tests failed\033[0m"
            # Cleanup temp files
            rm -f "$main_temp" "$linux_temp" "$progress_pid_file"
            return $main_exit_code
        fi

        if [[ "$include_linux" == "true" ]] && [[ $main_exit_code -eq 0 ]]; then
            # Start progress indicator for Linux tests
            {
                {
                    while true; do
                        echo -ne "\033[32m.\033[0m"
                        sleep 0.05
                    done
                } &
                echo $! > "$progress_pid_file"
            } 2>/dev/null
            local linux_progress_pid=$(cat "$progress_pid_file")

            # Run Linux tests silently
            _py_test_linux_only "$pytest_flags" > "$linux_temp" 2>&1

            # Kill progress indicator
            kill $linux_progress_pid 2>/dev/null
            wait $linux_progress_pid 2>/dev/null
            echo ""  # New line after dots

            # Extract Linux test summary (strip ANSI codes first)
            local linux_summary=$(sed 's/\x1b\[[0-9;]*m//g' "$linux_temp" | grep -oE "[0-9]+ passed in [0-9]+\.[0-9]+s" | head -1)
            local linux_count=$(echo "$linux_summary" | grep -oE "^[0-9]+")
            local linux_time=$(echo "$linux_summary" | grep -oE "[0-9]+\.[0-9]+s" | grep -oE "[0-9]+\.[0-9]+")

            # Calculate totals
            local total_count=$((main_count + linux_count))
            local total_time=$(echo "$main_time + $linux_time" | bc)

            # Print bold green total
            echo -e "\033[1;92m$total_count passed in ${total_time}s\033[0m"
        else
            # Print bold green summary
            echo -e "\033[1;92m$main_summary\033[0m"
        fi

        # Cleanup temp files
        rm -f "$main_temp" "$linux_temp" "$progress_pid_file"

        return $main_exit_code
    else
        # Verbose mode - just run normally
        _py_run_format_check_test "$pytest_flags"
        local main_exit_code=$?

        if [[ "$include_linux" == "true" ]] && [[ $main_exit_code -eq 0 ]]; then
            echo ""
            _py_test_linux_only "$pytest_flags"
        fi

        return $main_exit_code
    fi
}

function _py_check_test_naming()
{
    if [[ ($# -ne 0) ]]; then
        echo "No parameters should be given" >&2
        return 2
    fi

    local found_errors=0
    local exclude_search_dirs=(".venv" "node_modules" ".git" "__pycache__" ".pytest_cache" ".ruff_cache" "build" "dist")

    local find_exclude_args=""
    for exclude_dir in "${exclude_search_dirs[@]}"; do
        find_exclude_args="$find_exclude_args -path \"./$exclude_dir\" -prune -o"
    done

    while IFS= read -r file; do
        if [[ -n "$file" ]]; then
            echo "ERROR: $file - Test files should be named _test__*.py, not test_*.py" >&2
            ((found_errors++))
        fi
    done < <(eval "find . $find_exclude_args -type f -name 'test_*.py' -print")

    while IFS= read -r file; do
        if [[ -n "$file" && ! "$file" =~ /_test__.*\.py$ ]]; then
            echo "ERROR: $file - Test files should be named _test__*.py, not *_test.py" >&2
            ((found_errors++))
        fi
    done < <(eval "find . $find_exclude_args -type f -name '*_test.py' -print")

    if [[ $found_errors -eq 0 ]]; then
        return 0
    else
        echo "" >&2
        echo "Found $found_errors incorrectly named test file(s)" >&2
        return 1
    fi
}
###################################################################

###################################################################
# git
###################################################################

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

##############################################################


###################################################################
# docker
###################################################################

function op_docker_run_common_flags() 
{
	local ret="\
		-e RUNS_ON_DOCKER=true \
		--rm \
		--privileged=true \
		-v $PWD/../output/:/output/ \
		-v $PWD/../data/:/data/ \
		-v $PWD/../config/:/config/ \
		-v /:/top/ \
		--net=host \
		"
	echo "$ret"
}

function docker_out() 
{
    echo "=============================================="
    cat output/stdout_stderr_local_filenames.txt
    echo "=============================================="
    cat output/stdout_stderr_local_filenames.txt | xargs cat
    echo "=============================================="
}

# usage: 
# docker_run params_to_script
# The image name is the basename of current pwd converted to lowercase
function docker_run() 
{
	docker_run_name	$(basename_pwd_lower_case) $@
}

# usage:
# see docker_run
function docker_run_foreground() 
{
	docker_run_foreground_name $(basename_pwd_lower_case) $@
}

# usage:
# docker_run_name image_name params_to_script
function docker_run_name() 
{
  rm -f output/stdout_stderr_local_filenames.txt
	sudo docker run -d -e REDIRECT_OUTPUT=true $(op_docker_run_common_flags) $@
	sleep 3
	echo
    if test -f output/stdout_stderr_local_filenames.txt; then
        docker_out
    else
        echo "output was not created"
        echo "Check that you have ofirpele_utils.py and default_imports.py"
        echo "Check that the first line of your python run script is from default_imports import *"
        echo "Running docker_run_foreground_name $@"
        echo
        docker_run_foreground_name $@
    fi
}

# usage:
# see docker_run_name
function docker_run_foreground_name() 
{
	sudo docker run $(op_docker_run_common_flags) $@
}

# usage: docker_build
# The image name is the basename of current pwd converted to lowercase
function docker_build() 
{
	sudo docker build -t $(basename_pwd_lower_case) . 
}

# usage: docker_build_run
# The image name is the basename of current pwd converted to lowercase
function docker_build_run() 
{
	docker_build
	echo
	docker_run $@
}

# usage: docker_build image_name
function docker_build_name() 
{
	sudo docker build -t $@ . 
}

function docker_ps() 
{
	sudo docker ps
}

function docker_kill() 
{
	sudo docker container kill "$@"
}

function docker_killall() 
{		 
	sudo docker container kill $(sudo docker ps -q)
}

function docker_stop() 
{
	sudo docker container stop "$@"
}

function docker_stop_all() 
{
	sudo docker container stop $(sudo docker ps -q)
}

function docker_clean() 
{
	sudo docker container rm $(sudo docker container ls -aq)
	sudo docker image prune
}

function docker_image_ls() 
{
	sudo docker images
}

function docker_image_rm() 
{
	sudo docker image rm "$@"
}

function docker_killall_cleanall() 
{
	sudo docker container stop $(sudo docker ps -q)
	sudo docker container rm $(sudo docker container ls -aq)
	sudo docker image rm $(sudo docker images -aq)
}
###################################################################


#################################################################
#mail
#################################################################
function op_echo_attach_files() 
{
	for var in "$@"
	do
		echo -n "-a $var "
	done
}

# Usage: 
# mail_files filename1 filename2 ...
function mail_files() 
{
	eval $(echo "echo \"\" | mailx -s \""$@"\" -r $MY_EMAIL $(op_echo_attach_files $@) $MY_EMAIL")
}
#################################################################


#################################################################
# files and folder stuff
#################################################################
# http://www.bigsoft.co.uk/blog/2,008/04/11/configuring-ls_colors
#di is regular directory, ow is a writeable for others
export LS_COLORS='*.csv=01;35:*.json=01;36:*.user=00;90:*.sln=00;90:*.vcxproj=00;90:*.filters=00;90:*.hint=00;90:*.lock=00;90:*.ppt=01:*.odt=01:no=00:fi=00:di=01;33:ow=01;33:ln=01;36:pi=40;33:so=01;35:bd=44;32;01:cd=44;33;01:ex=01;32:*.cmd=01;32:*.exe=01;32:*.com=01;32:*.btm=01;32:*.bat=01;32:*.tar=36:*.tgz=36:*.rpm=36:*.deb=36:*.arj=36:*.taz=36:*.lzh=36:*.zip=36:*.z=36:*.Z=36:*.gz=36:*.rar=36:*.JPG=01;35:*.jpg=01;35:*.ppm=01;35:*.pgm=01;35:*.png=01;35:*.gif=01;35:*.bmp=01;35:*.xbm=01;35:*.xpm=01;35:*.tiff=01;35:*.tif=01;35:*.mp3=35:*.ogg=35:*.wav=35:*.au=35:*.mid=35:*.voc=35:*.mod=35:*.aiff=35:*.txt=01:*.html=01:*.htm=01:*.doc=01:*.ps=01:*.eps=01:*.pdf=01:*.lyx=01:*.py=91:*.c=91:*.cc=91:*.icc=91:*.cpp=91:*.cxx=91:*.hh=91:*.h=91:*.hpp=91:*.hxx=91:*.m=91:*.java=91:*.sh=32:*.csh=32:*.o=32:*.a=32:*.so=32:*.obj=32:*.class=32:*dockerfile=01;34:*Makefile=01;34:*README=01:*.md=01'
export LS_OPTIONS='--color=always -F -b -X'
alias ls='ls $LS_OPTIONS' 
alias l='ls  -lhSrXt'
alias LS='ls'
alias duls='du -h --max-depth=1'

#alias lsa='ls -lhaSrX'
#alias la='ls -lhaSrX'
#alias lh='ls --color=always -F -b -X | less -R'
#alias lsn='ls -lhSrXt \!* | cat -n'
#alias lsnmat='ls -lhSrXt *.mat | cat -n'
#alias lsnmatd='ls -lhSrXt \!*/*.mat | cat -n'
#alias ltex='ls  -lhSrXt *.tex'

# list only filenames and directory names in rows
function lslist() 
{
 ls | grep '.'
}

# list only filenames in rows
function lslistfiles() 
{
 find $@ -maxdepth 1 -type f -printf "%f\n"
}

# -H for filename
# -nr for line number
function gsenstive() 
{
 grep -nr -H --color=always $@
}

function g() 
{
 grep -nr -H -i --color=always $@
}

function gnoreg() 
{
 grep -nr -H -i --color=always -F -- $@
}

alias rmAll='rm -R * -f'

alias clean='rm -rf *~ .*~ #* *.o *.class *.dvi *.log *.aux java.log* matlab_crash*'

alias cleantex='rm -rf *~ *.o *.class *.dvi *.log *.aux java.log* matlab_crash* *.ps *.bbl *.blg *.aux *.brf *.dvi *.log *.bcf *.nav *.out *.snm *.toc *.vrb *.xml'

alias rm_zero_sized_files='find -size 0c -type f -exec rm -f {} \;'

# fixing the problem with less that runs on a shell that was run another shell. See here:
# https://www.unix.com/unix-for-dummies-questions-and-answers/114295-problems-using-less.html
function new_less() 
{
  if [[ $# -eq 2 && -f $2 ]]; then
    cat "$2" | $(which less) -R
    return
  fi
  if [[ $# -eq 1 ]]; then
    $(which less) -R
    return
  fi
  echo "${FUNCNAME[0]} works currently only with 0 arguments or 1 argument which is a file"
}

function cat_file_with_single_number_as_scientific()
{
    _require_nargs "$#" "filename <number of digits after decimal point>" 1 2 || return
    local private_digits_num=1
    if [[ ($# -eq 2) ]]; then
        local private_digits_num="$2"
    fi
    
    cat $1 | { read message; printf "%.${private_digits_num}e\n" "$message"; }
}

function chxsh() 
{
	chmod a+x *.sh
}

function convert_py_files_tabs_to_spaces() 
{
	find . -name '*.py' ! -type d -exec bash -c 'expand -t 4 "$0" > /tmp/e && mv /tmp/e "$0"' {} \;
}

function convert_file_to_ascii() 
{
		 iconv -f iso-8859-1 -t US-ASCII//TRANSLIT "$@" > "new_$@"
		 rm "$@" -f
		 mv "new_$@" "$@"
		 cat -n "$@" | perl -ne 'print if /[^[:ascii:]]/'
}

function find_lines_of_non_ascii() 
{
		 cat -n "$@" | perl -ne 'print if /[^[:ascii:]]/'
}

function find_lines_of_ascii() 
{
		 cat -n "$@" | perl -ne 'print if /[[:ascii:]]/'
}

# # add , to numbers >=1000
# function filethousands 
# {
# 		 cat $@ | op_thousands > $@.tmp
# 		 mv -f $@.tmp $@
# 		 grep [0-9] -nr -H -i --color=always $@ | grep --color=always ,
# }

# # used in filethousands
# function op_thousands 
# {
#     sed -re ' :restart ; s/([0-9])([0-9]{3})($|[^0-9])/\1,\2\3/ ; t restart '
# }
######################################################################


######################################################################
# media files
######################################################################

# cutvideo 00:01:00 00:02:00 in_file out_file
function cutvideo() 
{
  ffmpeg -ss "$1" -to "$2" -i "$3" -c copy "$4"
}
  
function reduce_mp4_quality_this_dir() 
{
  find ./ -type f -name "*.mp4" -exec /usr/bin/ffmpeg -i '{}' -c:v libx264 -preset slow -crf 40 -c:a copy '{}.small.mp4' \;
}

#function convert_ape_to_flac_this_dir() {
#		 find ./ -type f -name "*.ape"  -exec FILL_PATH/avconv -i '{}' '{}.flac' \;
#		 find ./ -type f -name "*.ape.flac" -exec rename 's/\.ape\.flac$/\.flac/' {} \;
#}

# function flacinthisdircuesplit()
# {
#   cp ~/utils/flaccuesplit ./
#   source flaccuesplit
#   rm flaccuesplit -f
# }

# function idtagalbumfix()
# {
#     # use this and then idtag to remove unwanted fields
# 	sudo mid3v2 --delete-frames=APIC *.mp3
# 	sudo mid3v2 --delete-frames=MCDI *.mp3
# 	sudo mid3v2 --delete-frames=TOAL *.mp3
# 	sudo mid3v2 --delete-frames=TRCK *.mp3
# 	sudo mid3v2 --delete-frames=TSOA *.mp3
# 	sudo mid3v2 --delete-frames=TPE2 *.mp3	
# }

# function idtag()
# {
#   # idtag -A "Sopranos" '*.mp3'
#   # idtag -p "1.jpg" '*.mp3'
#   sudo mid3v2 $@
# }
######################################################################

######################################################################
# pdf 
######################################################################
# locate SumatraPDF and open the given PDF (no file locking).
view_pdf() 
{
    local pdf_file="$1"

    # If SumatraPDF is on PATH, just use it.
    if command -v SumatraPDF >/dev/null 2>&1; then
        SumatraPDF -reuse-instance "$pdf_file" &
        return 0
    fi

    local candidates=(
        "$LOCALAPPDATA/SumatraPDF/SumatraPDF.exe"
        "/c/Program Files/SumatraPDF/SumatraPDF.exe"
        "/c/Program Files (x86)/SumatraPDF/SumatraPDF.exe"
        "$LOCALAPPDATA/Microsoft/WinGet/Links/SumatraPDF.exe"
    )

    local exe
    for exe in "${candidates[@]}"; do
        if [[ -x "$exe" ]]; then
            "$exe" -reuse-instance "$pdf_file" &
            return 0
        fi
    done

    echo "WARNING: SumatraPDF not found; falling back to the default PDF handler." >&2
    if command -v start >/dev/null 2>&1; then
        start "" "$pdf_file"
    else
        cmd.exe /c start "" "$pdf_file"
    fi
}

# Usage:
# pdfpages firstpage lastpage inputfile
# output: "inputfile_firstpage-lastpage.pdf"
function pdfpages()
{
    gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER \
       -dFirstPage=${1} \
       -dLastPage=${2} \
       -sOutputFile=${3%.pdf}_p${1}-p${2}.pdf \
       ${3}
}

function pdfjoinallfilestoalldotpdf()
{
	pdfunite *.pdf all.pdf
}

function pdfmergea4() 
{
 convert -resize 1240x1750 -background black -compose Copy -gravity center -extent 1240x1750 -units PixelsPerInch -density 150 $@
}

function pdfwordcount() 
{
 pdftotext $@ - | tr -d '.' | wc -w
}

# creates unencrypted.pdf
function pdfunlock() 
{
 gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile=unencrypted.pdf -c .setpdfwrite -f $@
}

function pdftoepspage() 
{
 pdftops -f $2 -l $2 -eps $1 $2.eps
}
######################################################################

######################################################################
# zip and friends
######################################################################
# unzip unrar ... for all formats and rm the zip/rar file
function u() 
{
 dtrx -r -n -q $@
 rm -f $@ 
}

# zip a directory to the same name
function zipr() 
{
 zip -r ${@%/}.zip ${@%/}/
}

function zipre() 
{
 zip -r -e $@.zip $@/
}

# compress, like zip
function tc() 
{
  tar -zcvf "$@"
}

# compress a folder a/b/c/ or c/ into ./c.tgz
function tcf()
{
  _require_nargs "$#" "folder_name" 1 || return
  tc ./$(basename $1).tgz "$1"
}

# uncompress, like unzip
function te()
{
  tar -zxvf "$@"
}
######################################################################


###################################################################
# helper functions
#
# Usage of 'func' that returns value:
#
# local var=$(func)
#
# Note: important not to have whitespace!
###################################################################
function basename_pwd()
{
    local ret=$(basename $(pwd))
    echo "$ret"
}

function basename_pwd_lower_case()
{
    local ret=$(basename_pwd)
	  local ret=${ret,,}
    echo "$ret"
}
###################################################################


######################################################################
# to sort
######################################################################
#TEMPERATURE=$(sensors | grep "Core 0" | cut -d + -f 2 | cut -d . -f1)
#
##if [ $TEMPERATURE -ge 30 ]; then
#echo "$TEMPERATURE" >> temps.txt
##fi# 

#alias code_see='a2ps -o tmp.ps --columns 1 --font-size=11 --line-numbers 1 \!*; gv tmp.ps &'

# uses .ispell_american
#alias spelltex	 'ispell -d american -t \!*'
#alias addBorder 'convert \!* -bordercolor black -border 1x1 \!*'

#alias ogg2mp3 'oggdec *.ogg; bladeenc -320 *.wav; rm *.wav -f; rm *.ogg -f'
#alias ogg2mp3 '~/utils/ogg2mp3'
#alias mq	'du -h>&! /tmp/duTmpFile; cat /tmp/duTmpFile | egrep "[0-9]M" | grep -v 'cannot' ; rm /tmp/duTmpFile -f'

# img2mov %08d.png -vcodec libx264 output.mov
# works nicely.  EXCEPT it doesn't work if the image dimensions aren't divisble by two.
#alias img2mov '/zain/projects/ffmpeg+x264/bin/ffmpeg -i \!*'

# wget -r -A png,pdf http://www.website-name.com
#alias gdbt='gdb --eval-command=run --eval-command=bt \!*'

# When starting a new project in VS: configure the compiler and linker to your g++ (e.g. the one above)
#function install_armadillo() {
#  sudo yum install cmake
#  sudo yum install openblas-devel
#  sudo yum install lapack-devel
#  sudo yum install arpack-devel
#  sudo yum install SuperLU-devel
#  ./configure
#  make
#  sudo make install
#}
######################################################################

###################################################################
# tex
###################################################################

# ---------------------------------------------------------------------------
# tex_compile: build a .tex file into a PDF and open it in SumatraPDF.
#
#   tex_compile [name|name.tex]
#
# Runs pdflatex twice so that \ref / \label cross-references and the table of
# contents resolve correctly.
# ---------------------------------------------------------------------------
tex_compile() {
    local input=$1
    local base="${input%.tex}"
    local tex_file="${base}.tex"
    local pdf_file="${base}.pdf"

    local out_dir
    out_dir="$(dirname "$tex_file")"

    if [[ ! -f "$tex_file" ]]; then
        echo "ERROR: '$tex_file' not found in $(pwd)." >&2
        return 1
    fi

    if ! command -v pdflatex >/dev/null 2>&1; then
        echo "ERROR: 'pdflatex' not found. Run '_tex_install' first (and open a new shell)." >&2
        return 1
    fi

    echo "==> Compiling $tex_file (pass 1/2)..."
    pdflatex -shell-escape -interaction=nonstopmode -halt-on-error -output-directory="$out_dir" "$tex_file" || {
        echo "ERROR: pdflatex failed. See ${base}.log for details." >&2
        return 1
    }

    echo "==> Compiling $tex_file (pass 2/2)..."
    pdflatex -shell-escape -interaction=nonstopmode -halt-on-error -output-directory="$out_dir" "$tex_file" || {
        echo "ERROR: pdflatex failed on second pass. See ${base}.log for details." >&2
        return 1
    }

    if [[ ! -f "$pdf_file" ]]; then
        echo "ERROR: expected '$pdf_file' was not produced." >&2
        return 1
    fi

    rm -f "${base}.aux" "${base}.log" "${base}.out"

    echo "==> Opening $pdf_file in SumatraPDF..."
    view_pdf "$pdf_file"
}

# not robust
_tex_install() {
    export PATH="$PATH:/c/Users/itama/AppData/Local/Programs/MiKTeX/miktex/bin/x64"
    export PATH="$PATH:$HOME/.cargo/bin"

    echo "==> Installing TeX distribution and tools via winget..."

    if ! command -v winget >/dev/null 2>&1; then
        echo "ERROR: 'winget' was not found. Install 'App Installer' from the" >&2
        echo "       Microsoft Store, then re-run tex_install." >&2
        return 1
    fi

    # MiKTeX: lightweight, installs missing packages on demand.
    echo "==> Installing MiKTeX..."
    winget install --id MiKTeX.MiKTeX --accept-source-agreements --accept-package-agreements -e || {
        echo "WARNING: MiKTeX install reported a non-zero exit code (may already be installed)." >&2
    }

    # SumatraPDF: fast viewer that does NOT lock the PDF file, so rebuilds work.
    echo "==> Installing SumatraPDF..."
    winget install --id SumatraPDF.SumatraPDF --accept-source-agreements --accept-package-agreements -e || {
        echo "WARNING: SumatraPDF install reported a non-zero exit code (may already be installed)." >&2
    }

    echo
    echo "==> NOTE: open a NEW shell so that 'pdflatex' is on PATH before compiling."
    echo "          MiKTeX auto-installs any missing package on first use."

    echo "==> Installing cargo (Rust) and tex-fmt..."

    if ! command -v cargo >/dev/null 2>&1; then
        if ! command -v winget >/dev/null 2>&1; then
            echo "ERROR: 'winget' was not found. Install 'App Installer' from the" >&2
            echo "       Microsoft Store, then re-run tex_fmt_install." >&2
            return 1
        fi

        echo "==> Installing rustup (provides cargo) via winget..."
        winget install --id Rustlang.Rustup --accept-source-agreements --accept-package-agreements -e || {
            echo "WARNING: rustup install reported a non-zero exit code (may already be installed)." >&2
        }

        # winget puts cargo in ~/.cargo/bin; make it available in THIS shell too.
        export PATH="$PATH:$HOME/.cargo/bin"
    fi

    if ! command -v cargo >/dev/null 2>&1; then
        echo "ERROR: 'cargo' still not found. Open a NEW shell and re-run tex_fmt_install." >&2
        return 1
    fi

    echo "==> Installing tex-fmt via cargo..."
    cargo install tex-fmt || {
        echo "ERROR: 'cargo install tex-fmt' failed." >&2
        return 1
    }

    echo
    echo "==> tex-fmt installed to ~/.cargo/bin. Open a NEW shell if 'tex-fmt' is not yet on PATH."
}
###################################################################

