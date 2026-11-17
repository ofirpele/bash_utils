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

function title_window_basename_pwd() {
  PROMPT_COMMAND="echo -ne \"\033]0;$(basename "$PWD")\007\""
}

function _parse_git_branch()
{
     git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'
     #git branch --show-current 2> /dev/null
}

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
