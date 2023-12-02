#!/usr/bin/env bash
#The following is a dynamic docstring that uses embedded variables,
#which are eval-ed by bash_docstring().
# # findgrep.bash
#
#   'findgrep' uses `find` to recursively search for all filenames in
#   a path that match `-name`, and then uses 'grep' to search for a
#   specified string within those files. If the string is found, the
#   filename and 'grep' search output are returned.
#
#   'findgrep' can be executed directly as a script, or sourced into
#   the current shell.
#
# ## Usage:
#   findgrep [find_path [grep_search]] [-options] [-grep_opts ...]
#
# ### Parameters:
#   find_path:
#     Path to recursively search for files. Defaults to current
#     directory ($PWD).
#
#   grep_search:
#     The string to search for within the files. Defaults to an empty
#     string (meaning `grep` is not performed on files).
#
#   grep_opts:
#     Additional options to pass to the `grep` command.
#
# ### Options:
# ```
#   -n|-name|--name find_name
#       Where `find_name` is the argument for the `find -name` option
#       in `find`, such as '*.bash' or '*.py', except for the
#       keywords 'bash', 'php', 'python', or 'shell'.
#       (See "Special Find Names" below.)
#
#   -C|--usecolor
#       Force use of ansi colour.
#   +C|+usecolor
#       Never use ansi color
#
#   -l|--files-with-matches
#       Only display file names, with no ansi color.
#
#   -m|-maxdepth|--maxdepth depth
#       Where `depth` is the argument for the `find -maxdepth` option.
#       Default is unlimited.
#
#   -v|--verbose
#       Be verbose
#   -q|--quiet
#       Be not verbose
#
#   -V|--version
#       Print version: '$PRGNAME $VERSION'
#
#   -h|--help
#       This `bash_docstring`.(Not available if this script is
#       `source`d as a function.)
# ```
#
# ## Examples:
#
#   ```
#   findgrep ~/lib -name '*.bash' 'openai' -i
#
#   findgrep ~/scripts --name py '__main__' -m1
#
#   findgrep . '__main__' -name '*' -m1
#
#   findgrep . -n shell 'trim ' >/tmp/funcs_using_trim
#
#   findgrep /ai/scripts/lib -n shell 'trim ' -ql
#
#   ```
#
# ## Dependencies:
#   $DEPENDENCIES
#
# ## Error Handling:
#   The script exits if any command returns a non-zero status, if any
#   variable is us before being set, or if any part of a pipeline
#   fails.
#
# ## Special Find Names:
#   If 'find_name' equals 'bash', 'php', 'python', or 'shell', then
#   'findgrep' will search all text files regardless of extension for
#   the presense of an appropriate hashbang (#!/(*) or <?(*)) for a
#   range of file extensions related to those types of files.
#
#   Note that use of these keyword names will incur additional
#   processing overhead.
#
#   bash: matches files with file extension .bash|.sh, or files with
#   hashbangs containing /bash|/sh.
#
#   shell: matches files with file extension .bash|.sh|.zsh, or files
#   with hashbangs containing /bash|/sh|/zsh.
#
#   python: matches files with file extension .py|.python, or files
#   with hashbangs containing /python.
#
#   php: matches files with file extension .php, or files with
#   hashbangs containing /php, or files with a header starting
#   with '<?php'.
#
# ### Author: $AUTHOR, $ORGANIZATION
#
# ### Updated: $UPDATED
#
# ### Version: $VERSION
#
# ### Repository: $REPOSITORY
#
# ### Licence: $LICENCE
#

usage() {
  echo "$PRGNAME $VERSION"
  echo " Desc: $DESCRIPTION"
  echo "Usage: $USAGE"
  exit
}
findgrep() {
  # #canonical Provenence Globals for scripts
  declare -r  PRGNAME="${FUNCNAME[0]}" \
              VERSION='0.4.20' \
              UPDATED='2023-11-30' \
              AUTHOR='Gary Dean' \
              ORGANISATION='Open Technology Foundation' \
              LICENSE='GPL3' \
              DESCRIPTION='find and grep files at the same time.' \
              DEPENDENCIES='find grep'
  declare -r  USAGE="$PRGNAME [find_path [grep_search]] [-options] [-grep_opts ...]" \
              REPOSITORY="https://github.com/Open-Technology-Foundation/${PRGNAME}"
  declare -n  ORGANIZATION=ORGANISATION AUTHORS=AUTHOR LICENCE=LICENSE

  # semantic helper functions equivalent to `echo`
  msg()      { echo -n "${PRGNAME}: "; echo "$@"; }
  msg.info() { >&2 msg 'info:'  "$@"; }
  msg.err()  { >&2 msg 'error:' "$@"; }
  msg.die()  { >&2 msg 'die:'   "$@"; exit 1; }

  # findgrep find_path grep_search [gopts...]
  local -i usecolour=0
  local -- colour=auto
  usecolour=$(tput colors 2>/dev/null || echo 0)
  ((usecolour)) && colour=always
  [[ -n "${PS1:-}" ]] && [[ $(tput colors 2>/dev/null) -ge 8 ]] \
      && { usecolour=1; colour=always; }
  local -- find_path='.'
  local -- grep_search=''
  local -a gopts=() \
           fopts=( '-maxdepth' '5' '-type' 'f' '-name' '"*"' '-size' '-100000c' )
           #        0           1   2       3   4       5     6       7
  local -i  MD=1 TP=3 NM=5 SZ=7
  local -n find_name=fopts[NM]

  local -- file
  local -i files_with_matches=0
  local -i verbose=1

  # shellcheck disable=SC2206
  local -a args=()
  while (($#)); do case $1 in
    -n|-name|--name)
                    shift;
                    (($#)) && { find_name="$1"; } ;;
    -C|--usecolour|--usecolor|-usecolor)
                    usecolour=1
                    colour=auto
                    gopts+=( '--color=auto' ) ;;
    +C|-+usecolour|-+usecolor|+usecolor)
                    usecolour=0
                    colour=never
                    gopts+=( '--color=never' ) ;;
    -l|--files-with-matches)
                    files_with_matches=1
                    usecolour=0
                    colour=never
                    gopts+=( '--color=never' '--files-with-matches' ) ;;
    -m|-maxdepth)   shift
                    (($#)) && fopts[MD]="$1" ;;
    -v|--verbose)   verbose=1 ;;
    -q|--quiet)     verbose=0 ;;
    -V|--version)   echo "$PRGNAME $VERSION"; return 0 ;;
    -h|--help)      bash_docstring -e "$0"; return 0 ;;
    -[nClLvqVh]*)   #shellcheck disable=SC2046 # expand aggregated short options
                    set -- '' $(printf -- "-%c " $(grep -o . <<<"${1:1}")) "${@:2}"
                    ;;
    -*)             gopts+=( "$1" ) ;;
    *)              args+=( "$1" ) ;;
  esac; shift; done

  # Examine the arguments.
  #   no more than 2: find_path and grep_search.
  ((${#args[@]})) && {
    find_path="${args[0]}"
    ((${#args[@]} > 1)) && {
      grep_search="${args[1]}"
      ((${#args[@]} > 2)) && {
        msg.die 'Too many arguments.'
      }
    }
  }

  # Process the find_names
  #   check for special keywords, else send to find as is.
  local -a file_paths=()
  # bash -----------------
  if [[ $find_name == 'bash' ]]; then
    find_name='*'
    ((DEBUG)) && {
      >&2 echo "---$LINENO: $(declare -p file_paths fopts)";
      >&2 declare -p find_name fopts gopts
      >&2 echo "find -L -O3 \"$find_path\" ${fopts[@]} -exec readlink -f \"{}\" \; |sort -u"
    }
    local -- fext
    while read -r fext; do
      [[ $fext =~ \.(bash|sh)$ ]] \
          && { file_paths+=( "$fext" ); continue; }
      [[ $(_head1 "$fext") =~ ^\#\!.*(/bash|/sh) ]] \
          && file_paths+=( "$fext" )
    done < <(find -L -O3 "$find_path" "${fopts[@]}"  -exec readlink -f "{}" \; |sort -u)
  # shell ----------------
  elif [[ $find_name == 'shell' ]]; then
    find_name='*'
    while read -r; do
      [[ $REPLY =~ \.(bash|sh|zsh)$ ]] \
          && { file_paths+=( "$REPLY" ); continue; }
      [[ $(_head1 "$REPLY") =~ ^\#\!.*(/bash|/sh|/zsh) ]] \
          && file_paths+=( "$REPLY" )
    done < <(find -L -O3 "$find_path" "${fopts[@]}" -exec readlink -f "{}" \; |sort -u)
  # py -------------------
  elif [[ $find_name == 'py' || $find_name == 'python' ]]; then
    find_name='*'
    while read -r; do
      [[ $REPLY =~ \.(py|python)$ ]] \
          && { file_paths+=( "$REPLY" ); continue; }
      [[ $(_head1 "$REPLY") =~ ^\#\!.*(/python|/py) ]] \
          && file_paths+=( "$REPLY" )
    done < <(find -L -O3 "$find_path" "${fopts[@]}" -exec readlink -f "{}" \; |sort -u)
  # php ------------------
  elif [[ $find_name == 'php' ]]; then
    find_name='*'
    while read -r; do
      [[ $REPLY =~ \.(php)$ ]] \
          && { file_paths+=( "$REPLY" ); continue; }
      [[ $(_head1 "$REPLY") =~ ^\#\!.*(/php) ]] \
        || [[ $(_head1 "$REPLY") =~ ^\<\? ]] \
          && file_paths+=( "$REPLY" )
    done < <(find -L -O3 "$find_path" "${fopts[@]}" -exec readlink -f "{}" \; |sort -u)

  # default --------------
  else
    readarray -t file_paths < <(
      find -L -O3 "$find_path" "${fopts[@]}" -exec readlink -f "{}" \; |sort -u
    )
  fi

  ((${#file_paths[@]})) || {
    ((verbose)) && >&2 msg '0 files found.'
    return 1
  }

  local -i filecount=0
  local -a indent=( /usr/bin/sed 's/^/    /' )
  for file in "${file_paths[@]}"; do
    (("${#grep_search}")) || {
      filecount+=1
      ((usecolour)) \
          && echo -e "\e[38;5;1m${file}\e[0m" \
          || echo "$file"
      continue
    }
    if grep -m1 -qs ${gopts[*]} "$grep_search" "$file"; then
      filecount+=1
      if ((files_with_matches == 0)); then
        ((usecolour)) \
            && echo -e "\e[38;5;1m${file}\e[0m:" \
            || echo "$file:"
      else
        indent=( cat '-s' )
      fi
      grep --line-number -s --colour="$colour" ${gopts[*]} "$grep_search" "$file" | "${indent[@]}"
    fi
  done
  ((verbose)) && >&2 msg "$filecount file$( ((filecount!=1)) && echo 's')"
}
declare -fx findgrep


#Source: head
#Repository: 'yatti-lib' -> https://github.com/Open-Technology-Foundation/yatti-lib
#LocalDir: /ai/scripts/lib/./head
_head1 () {
    local -a line;
    [[ -f "$1" ]] || return 0
    mapfile -t -n 1 line < "$1"
    ((${#line[@]})) || return 0
    printf '%s' "$line"
}
declare -fx _head1

bash_docstring ()
{
    declare -r PRGNAME="${FUNCNAME[0]}" VERSION='0.4.20' UPDATED='2023-11-30' AUTHOR='Gary Dean' ORGANISATION='Open Technology Foundation' LICENSE='GPL3' DESCRIPTION='Docstrings for Bash.' DEPENDENCIES='Bash >= 5';
    declare -r USAGE="$PRGNAME [-e] [source_file [function_name]]" REPOSITORY="https://github.com/Open-Technology-Foundation/${PRGNAME}";
    declare -n ORGANIZATION=ORGANISATION AUTHORS=AUTHOR LICENCE=LICENSE;
    local -i _eval=0;
    local -a _arg=();
    while (($#)); do
        case "$1" in
            -e | --eval)
                _eval=1
            ;;
            +e | --no-eval)
                _eval=0
            ;;
            -V | --version)
                echo "$PRGNAME $VERSION";
                return 0
            ;;
            -h | --help)
                bash_docstring -e '' "${FUNCNAME[0]}" | /usr/bin/less -R -FXRS;
                return 0
            ;;
            -[eVh]*)
                set -- '' $(printf -- "-%c " $(grep -o . <<<"${1:1}")) "${@:2}"
            ;;
            -? | --*)
                echo "${FUNCNAME[0]}: error: Invalid option '$1'" 1>&2;
                return 22
            ;;
            *)
                ((${#_arg[@]} > 2)) && {
                    echo "${FUNCNAME[0]}: error: Invalid argument '$1'" 1>&2;
                    return 2
                };
                _arg+=("$1")
            ;;
        esac;
        shift;
    done;
    local -- input_from="${PRG0:-"${0:-}"}";
    ((${#_arg[@]} > 0)) && ((${#_arg[0]})) && input_from="${_arg[0]}";
    [[ -f "$input_from" ]] || {
        echo "${FUNCNAME[0]}: error: Source file '$input_from' not found" 1>&2;
        return 1
    };
    local -- input_from_base="${input_from##*/}";
    local -- funcname='';
    ((${#_arg[@]} > 1)) && funcname="${_arg[1]}";
    funcname="${funcname//[ \(\)]/}";
    local -- ofuncname="$funcname";
    local -- ln;
    while IFS= read -r ln; do
        [[ "${ln:0:2}" == '#!' ]] && continue;
        ln="${ln#"${ln%%[![:blank:]]*}"}";
        ln="${ln%"${ln##*[![:blank:]]}"}";
        [[ -z "$ln" ]] && continue;
        if [[ -n "$funcname" ]]; then
            [[ $ln =~ ^(function[[:blank:]]+)?$funcname[[:blank:]]*\(\) ]] && funcname='';
            continue;
        fi;
        [[ ${ln:0:1} == '#' ]] || return 0;
        [[ $ln == '#' ]] && {
            echo;
            continue
        };
        [[ ${ln:0:2} == '# ' ]] || continue;
        [[ $ln == *'shellcheck'* ]] && continue;
        if ((_eval)); then
            ln="${ln//\"/\\\"}";
            ln="${ln//\`/\\\`}";
            ln="${ln//\$\(/\\\$ \(}";
            [[ "${ln:2:1}" == '-' ]] && ln="#  ${ln:2}";
            eval "echo \"${ln:2}\"";
        else
            [[ "${ln:2:1}" == '-' ]] && ln="#  ${ln:2}";
            echo "${ln:2}";
        fi;
    done < "$input_from";
    echo "${FUNCNAME[0]}: error: Bash docstring not found for $input_from_base:${ofuncname:-'script'}" 1>&2;
    return 1
}
declare -fx bash_docstring

# Run as script if not sourced ==================================
# #canonical Test for source/script
[[ "${BASH_SOURCE[0]:-}" == "$0" ]] && {
  # #canonical SET options for command scripts.
  set -euo pipefail

  # #canonical DEBUG setup
  # (use of -g is deliberate; no time to explain; trust me.)
  # force any existing DEBUG to int
  declare -ixg DEBUG=${DEBUG:-0}
  # DEBUG>1 sets -xv and PS4
  ((DEBUG>1)) && { declare -xg PS4='+ $LINENO: '; set -xv; }

  findgrep "$@"
}

#fin
