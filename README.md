# findgrep.bash

  'findgrep' uses `find` to recursively search for all filenames in
  a path that match `-name`, and then uses 'grep' to search for a
  specified string within those files. If the string is found, the
  filename and 'grep' search output are returned.

  'findgrep' can be executed directly as a script, or sourced into
  the current shell.

## Usage:
  findgrep [find_path [grep_search]] [-options] [-grep_opts ...]

### Parameters:
  find_path:
    Path to recursively search for files. Defaults to current
    directory (/ai/scripts/findgrep).

  grep_search:
    The string to search for within the files. Defaults to an empty
    string (meaning `grep` is not performed on files).

  grep_opts:
    Additional options to pass to the `grep` command.

### Options:
```
  -n|-name|--name find_name
      Where `find_name` is the argument for the `find -name` option
      in `find`, such as '*.bash' or '*.py', except for the
      keywords 'bash', 'php', 'python', or 'shell'.
      (See "Special Find Names" below.)

  -C|--usecolor
      Force use of ansi colour.
  +C|+usecolor
      Never use ansi color

  -l|--files-with-matches
      Only display file names, with no ansi color.

  -m|-maxdepth|--maxdepth depth
      Where `depth` is the argument for the `find -maxdepth` option.
      Default is unlimited.

  -v|--verbose
      Be verbose
  -q|--quiet
      Be not verbose

  -V|--version
      Print version: 'bash_docstring 0.4.20'

  -h|--help
      This `bash_docstring`.(Not available if this script is
      `source`d as a function.)
```

## Examples:

  ```
  findgrep ~/lib -name '*.bash' 'openai' -i

  findgrep ~/scripts --name py '__main__' -m1

  findgrep . '__main__' -name '*' -m1

  findgrep . -n shell 'trim ' >/tmp/funcs_using_trim

  findgrep /ai/scripts/lib -n shell 'trim ' -ql

  ```

## Dependencies:
  Bash >= 5

## Error Handling:
  The script exits if any command returns a non-zero status, if any
  variable is us before being set, or if any part of a pipeline
  fails.

## Special Find Names:
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

  python: matches files with file extension .py|.python, or files
  with hashbangs containing /python.

  php: matches files with file extension .php, or files with
  hashbangs containing /php, or files with a header starting
  with '<?php'.

### Author: Gary Dean, Open Technology Foundation

### Updated: 2023-11-30

### Version: 0.4.20

### Repository: https://github.com/Open-Technology-Foundation/bash_docstring

### Licence: GPL3

