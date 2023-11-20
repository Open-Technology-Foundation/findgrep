#!/bin/bash

findgrep() {
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
    -L|-maxdepth)   shift
                    (($#)) && fopts[MD]="$1" ;;
    -v|--verbose)   verbose=1 ;;
    -q|--quiet)     verbose=0 ;;
    -V|--version)   echo "${FUNCNAME[0]} vs $version"; return 0 ;;
    -h|--help)      usage; return 0 ;;
    -[ClLvqVh]*)    #shellcheck disable=SC2046 # expand aggregated short options
                    set -- '' $(printf -- "-%c " $(grep -o . <<<"${1:1}")) "${@:2}"
                    ;;
    -*)             gopts+=( "$1" ) ;;
    *)              args+=( "$1" ) ;;
  esac; shift; done

  ((${#args[@]})) && {
    find_path="${args[0]}"
    ((${#args[@]} > 1)) && {
      grep_search="${args[1]}"
      ((${#args[@]} > 2)) && {
        >&2 echo "${FUNCNAME[0]}: Too many arguments."
        return 1
      }
    }
  }

  local -a file_paths=()
  # bash -----------------
  if [[ $find_name == 'bash' ]]; then
    find_name='*'
    ((DEBUG)) && {
      >&2 echo "---$LINENO: $(declare -p file_paths fopts)";
      >&2 declare -p find_name fopts gopts
      >&2 echo "find \"$find_path\" ${fopts[@]}"
    }
    local -- fext
    while read -r fext; do
      [[ $fext =~ \.(bash|sh)$ ]] \
          && { file_paths+=( "$fext" ); continue; }
      [[ $(_head1 "$fext") =~ ^\#\!.*(/bash|/sh) ]] \
          && file_paths+=( "$fext" )
    done < <(find "$find_path" "${fopts[@]}" )
  # shell ----------------
  elif [[ $find_name == 'shell' ]]; then
    find_name='*'
    while read -r; do
      [[ $REPLY =~ \.(bash|sh|zsh)$ ]] \
          && { file_paths+=( "$REPLY" ); continue; }
      [[ $(_head1 "$REPLY") =~ ^\#\!.*(/bash|/sh|/zsh) ]] \
          && file_paths+=( "$REPLY" )
    done < <(find "$find_path" "${fopts[@]}")
  # py -------------------
  elif [[ $find_name == 'py' || $find_name == 'python' ]]; then
    find_name='*'
    while read -r; do
      [[ $REPLY =~ \.(py|python)$ ]] \
          && { file_paths+=( "$REPLY" ); continue; }
      [[ $(_head1 "$REPLY") =~ ^\#\!.*(/python|/py) ]] \
          && file_paths+=( "$REPLY" )
    done < <(find "$find_path" "${fopts[@]}")
  # php ------------------
  elif [[ $find_name == 'php' ]]; then
    find_name='*'
    while read -r; do
      [[ $REPLY =~ \.(php)$ ]] \
          && { file_paths+=( "$REPLY" ); continue; }
      [[ $(_head1 "$REPLY") =~ ^\#\!.*(/php) ]] \
        || [[ $(_head1 "$REPLY") =~ ^\<\? ]] \
          && file_paths+=( "$REPLY" )
    done < <(find "$find_path" "${fopts[@]}")

  # default --------------
  else
    ((DEBUG > 1)) && >&2 declare -p find_path fopts
    readarray -t file_paths < <(eval find "$find_path" ${fopts[@]})
  fi

  ((${#file_paths[@]})) || {
    >&2 echo "${FUNCNAME[0]}: 0 files found."
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
  ((verbose)) && >&2 echo "${FUNCNAME[0]}: $filecount file$( ((filecount!=1)) && echo 's')"
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

# Run as script if not sourced
[[ "${BASH_SOURCE[0]:-}" == "$0" ]] && {
  set -euo pipefail
  [[ -v DEBUG ]] || declare -i DEBUG=0
  DEBUG=$((DEBUG)); ((DEBUG>1)) && { PS4='+ $LINENO: '; set -xv; }

  (($# == 0)) || [[ " $* " =~ " -h " ]] || [[ " $* " =~ " --help " ]] && {
    cat <<'EOT'
findgrep.bash:
  'findgrep' uses 'find' to recursively search for all filenames in a
   path that match -name, and then uses 'grep' to search for a
   specified string within those files. If the string is found, the
   filename and 'grep' search output are returned.

  'findgrep' can be executed directly as a script, or sourced into
   the current shell.

Usage: findgrep [find_path [grep_search]] [-grep_opts ...]

Parameters:
  find_path: The path in which to search for files.
    Defaults to the current directory.

  grep_search: The string to search for within the files.
    Defaults to an empty string (meaning 'grep' not preformed).

  grep_opts: Additional options to pass to the 'grep' command.

Examples:
  findgrep ~/dv --name '*' 'openai' -i

  findgrep ~/scripts --name '*.py' '__main__' -m1

  findgrep . '__main__' -name '*' -m1

  findgrep . -n shell 'trim ' >/tmp/funcs_using_trim

  findgrep ~ shell 'trim ' >/tmp/funcs_with_trim

Dependencies:
  This script requires the 'grep' and 'find' commands to be
  available on the system.

Error Handling:
  The script exits if any command returns a non-zero status, if any
  variable is us before being set, or if any part of a pipeline
  fails.

Note:
  If 'find_name' equals 'bash', 'php', 'python', or 'shell', then
  'findgrep' will search all text files regardless of extension for
  the presense of an appropriate hashbang (#!/(*) or <?(*)) for a
  range of file extensions related to those types of files.

  Note that use of these keyword names will incur additional
  processing overhead.

  bash: matches files with file extension .bash|.sh, or files with
  hashbangs containing /bash|/sh.

  shell: matches files with file extension .bash|.sh|.zsh, or files
  with hashbangs containing /bash|/sh|/zsh.

  python: matches files with file extension .py|.python, or files with
  hashbangs containing /python.

  php: matches files with file extension .php, or files with
  hashbangs containing /php, or files with a header starting
  with '<?php'.

Author: Gary Dean, Open Technology Foundation

Date: 2023-11-07

Version: 0.4.20

EOT
    exit 0
  }
  findgrep "$@"
}

#fin
