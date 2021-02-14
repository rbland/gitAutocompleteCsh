# Overview
This repository provides a tab-completion script to be used in a csh or tcsh shell. For reasons unknown, my past two jobs used tcsh by default. Importantly, this script can be used to discover and complete custom git sub-commands if they are installed into the same directory as the completion script (it could be updated to scan all locations on `$PATH` but I decided to avoid this for performance).

Although the completion is for tcsh, you may notice the script itself is implemented in bash. This was for sanity.

# Installation
Copy the two scripts to a desired location then add the following to your `~/.tcshrc` or other shell initializer:
```
source /path/to/init.sh
```
To verify it is working, open a new shell, navigate to any git repository, type "git " and press tab. You should see your shell list git sub-commands.

# Features
## Commands
The script can be used to autocomplete the following built-in sub-commands and subsequent arguments/options:
* add
* bisect
* blame
* branch
* checkout
* clone
* commit
* config
* diff
* difftool
* fetch
* grep
* gui
* init
* log
* merge
* mv
* pull
* push
* rebase
* remote
* reset
* rm
* show
* stash
* status
* tag
## Argument/Option Completion
Depending on the sub-command the following can be completed:
* filesystem tokens
* local branch names
* remote branch names
* remote names
* tag names
* commit SHAs
* options