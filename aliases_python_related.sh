# current time in integer milliseconds
function _now_ms()
{
    echo $(( $(date +%s%N) / 1000000 ))
}

# format integer milliseconds as seconds with 2 decimals, e.g. 1374 -> 1.37
function _ms_to_s()
{
    printf "%d.%02d" $(( $1 / 1000 )) $(( $1 % 1000 / 10 ))
}

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
    local best_ms_test=999999999
    local best_threads_test=1
    local degradation_threshold_pct=105

    for threads in "${thread_counts[@]}"; do
        echo -n "Testing with $threads threads... "

        local total_ms=0
        local runs=3

        for ((i=1; i<=runs; i++)); do
            local start_ms=$(_now_ms)
            uv run pytest -q -n $threads > /dev/null 2>&1
            local end_ms=$(_now_ms)
            (( total_ms += end_ms - start_ms ))
        done

        local avg_ms=$(( total_ms / runs ))
        echo "Average time: $(_ms_to_s $avg_ms)s"

        if (( avg_ms < best_ms_test )); then
            best_ms_test=$avg_ms
            best_threads_test=$threads
        elif (( avg_ms * 100 > best_ms_test * degradation_threshold_pct )); then
            echo "  Performance degradation detected. Stopping regular test tuning."
            break
        fi
    done

    echo ""
    echo "--- Testing pytest with COVERAGE ---"
    local best_ms_cov=999999999
    local best_threads_cov=1

    for threads in "${thread_counts[@]}"; do
        echo -n "Testing with $threads threads... "

        local total_ms=0
        local runs=2

        for ((i=1; i<=runs; i++)); do
            local start_ms=$(_now_ms)
            uv run pytest -q --cov --cov-report= -n $threads > /dev/null 2>&1
            local end_ms=$(_now_ms)
            (( total_ms += end_ms - start_ms ))
        done

        local avg_ms=$(( total_ms / runs ))
        echo "Average time: $(_ms_to_s $avg_ms)s"

        if (( avg_ms < best_ms_cov )); then
            best_ms_cov=$avg_ms
            best_threads_cov=$threads
        elif (( avg_ms * 100 > best_ms_cov * degradation_threshold_pct )); then
            echo "  Performance degradation detected. Stopping coverage test tuning."
            break
        fi
    done

    echo ""
    echo "=========================================="
    echo "RESULTS:"
    echo "Regular pytest: $best_threads_test threads ($(_ms_to_s $best_ms_test)s)"
    echo "Coverage pytest: $best_threads_cov threads ($(_ms_to_s $best_ms_cov)s)"
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
    #_py_check_test_naming || return $?
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
            local total_time=$(awk -v a="$main_time" -v b="$linux_time" 'BEGIN{printf "%.2f", a+b}')

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
