#!/bin/bash --norc

# unaliasing for safety
unalias -a

working_dir=$PWD

local_cache="${working_dir}/.gitCompleteCache.dat"
local_repos=()
local_branches=()
local_issues=()


# the array of git built-in commands
builtin_cmds=(add bisect blame branch checkout clone commit config diff difftool\
 fetch grep gui init log merge mv pull push rebase remote reset rm show stash status tag)

# the global array of eligible completion tokens to be populated
complete_tokens=()
# the global array of valid options for the current sub-command
options=()

# populates results to autocomplete the git immediate sub-command
completeSubcommand()
{
    if [ -d "$PWD/.git" ]; then
        # if in a Git repository add built-in subcommands.
        complete_tokens=(${complete_tokens[@]} ${builtin_cmds[@]})
    fi
    addCustomSubcommands
}

# add tokens to the completion array from the custom Git subcommands.
addCustomSubcommands()
{
    # discover any custom git sub-commands in the gitTools/bin directory.
    binDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
    prefix="${binDir}/git-"
    for filename in ${prefix}*; do
        complete_tokens+=("${filename#"$prefix"}")
    done
}

# add tokens to the completion array from the specified cache file
addCacheTokens()
{
    if [ -f $1 ]; then
        tokens=($(cat $1))
        complete_tokens=(${complete_tokens[@]} ${tokens[@]})
    fi
}


##########################
# Completion population from cache files
##########################

# populates auto-completion results with all local repo names
addLocalRepoFilters()
{
    complete_tokens=(${complete_tokens[@]} ${local_repos[@]})
}

# populates auto-completion results with all local issue branch names
addLocalIssueFilters()
{
    complete_tokens=(${complete_tokens[@]} ${local_issues[@]})
}

# populates auto-completion results with all local non-issue branch names
addLocalBranchFilters()
{
    complete_tokens=(${complete_tokens[@]} ${local_branches[@]})
}


##########################
# Multi-cache token completions
##########################

# populates auto-completion results with all local search terms
addLocalFilters()
{
    # populate completion tokens from cache.
    addLocalRepoFilters
    addLocalIssueFilters
    addLocalBranchFilters
}

##########################
# Built-in git command completion tools.
##########################

addRemoteNames()
{
    tokens=`git remote 2>/dev/null`
    complete_tokens=(${complete_tokens[@]} ${tokens[@]})
}

addTagNames()
{
    tokens=`git tag -l 2>/dev/null | xargs`
    complete_tokens=(${complete_tokens[@]} ${tokens[@]})
}

addCommitShas()
{
    tokens=(`git log -q --pretty=format:%h --max-count $1 2>/dev/null | xargs`)
    complete_tokens=(${complete_tokens[@]} ${tokens[@]})
}


# adds tab completion for partial file names
addFileCompletion()
{
    # get the completion of all directories and files.
    dirs=( $(compgen -d -- "$1" | xargs) )
    files=( $(compgen -f -- "$1" | xargs) )
    
    # Remove directories from list of files...
    files=( $(printf "%s\n" "${files[@]}" "${dirs[@]}" | sort | uniq -u) )
    
    # Append a trailing slash to all directories.
    dirs2=(${dirs[@]/%//})
    # Append a plus to all directories. This prevents a space from being added by tab-completion.
    dirs3=(${dirs2[@]/%/+})
    
    complete_tokens=(${complete_tokens[@]} ${dirs2[@]})
    complete_tokens=(${complete_tokens[@]} ${dirs3[@]})
    complete_tokens=(${complete_tokens[@]} ${files[@]})
}

# adds tab completion for partial file names that are tracked by Git.
addTrackedFileCompletion()
{
    tokens=(`git ls-tree -r HEAD --name-only 2>/dev/null | xargs`)
    complete_tokens=(${complete_tokens[@]} ${tokens[@]})
}

addLocalBranchNames()
{
    tokens=(`git for-each-ref --format="%(refname)" refs/heads 2>/dev/null | sed -e s,refs/heads/,, | xargs`)
    complete_tokens=(${complete_tokens[@]} ${tokens[@]})
}

addRemoteBranchNames()
{
    tokens=(`git for-each-ref --format="%(refname)" refs/remotes/origin 2>/dev/null | grep -v HEAD | sed -e s,refs/remotes/origin/,, | xargs`)
    complete_tokens=(${complete_tokens[@]} ${tokens[@]})
}


##########################
# Execution main entry point.
##########################
doIt()
{
    testMode=false
    if [ -z ${COMMAND_LINE+x} ]; then
        # for testing purposes, get the command line from arguments.
        COMMAND_LINE="$@"
        testMode=true
    fi 
    
    # strip the "git " from the command line.
    command="${COMMAND_LINE#"git "}"

    # split the tokens in the command-line into components.
    IFS=' ' # the split character
    read -r -a words<<<$command
    subcommand=""
    word="" 
    previous=""
    wordNumber=${#words[@]}
    
    if [ $wordNumber -gt 0 ]; then
        if [ ${#words[@]} -eq 1 ]; then
            # only a single word has been entered so far.
            word=${words[0]}
        else
            # the command includes multiple words after a sub-command, complete sub-command arguments.
            subcommand=${words[0]}
            word=${words[-1]}
            previous=${words[-2]}
        fi

        # check if the command ends with a space, indicating a new word should be started.
        echo "$command" | grep -P -q "\s$"
        if [ $? == 0 ]; then
            # the command line ends with a space, start completing a new word
            word=""
            previous=${words[-1]}
            subcommand=${words[0]}
            wordNumber=$((wordNumber+1))
        fi
    fi
    
    # clear global token accumulators
    complete_tokens=()
    options=()
    case $subcommand in
        "")
            completeSubcommand
            ;;
        help)
            complete_tokens=(${builtin_cmds[@]})
            ;;
        add)
            addFileCompletion $word
            options=(--verbose --dry-run --force --interactive --patch --edit --update --refresh)
            ;;
        rm)
            addTrackedFileCompletion
            addFileCompletion
            options=(--quiet --force --cached --ignore-unmatch)
            ;;
        mv)
            addFileCompletion $word
            options=(--force --dry-run --verbose -k)
            ;;
        blame)
            options=(-c -b -l -t -f -n -s -e -p -w --root --incremental)
            addFileCompletion $word
            ;;
        branch)
            addLocalBranchNames
            options=(--move --delete --list --all --copy --force)
            ;;
        checkout)
            addLocalBranchNames
            addFileCompletion $word
            options=(-b -B --force --quiet)
            ;;
        config)
            options=(--global --get-regexp --list)
            ;;
        commit)
            addFileCompletion $word
            options=(--interactive --all --message --amend)
            ;;
        diff)
            addLocalBranchNames
            addFileCompletion $word
            options=(--check --staged --state --)
            ;;
        difftool)
            addLocalBranchNames
            addFileCompletion $word
            options=(--no-prompt --staged --)
            ;;
        merge)
            case $wordNumber in
                2)
                    addLocalBranchNames
                    ;;
                *)
                   options=(--ff --no-ff --ff-only --squash --strategy --stat --quiet --verbose --progress -m --abort --continue)
                   ;;
            esac
            ;;
        log)
            addFileCompletion $word
            options=(--decorate --source --skip --author --grep --no-merges --max-count)
            ;;
        stash)
            options=(apply list save pop clear)
            ;;
        push)
            case $wordNumber in
                2)
                    addRemoteNames
                    ;;
                3)
                    addLocalBranchNames
                    ;;
                *)
                   options=(--tags --dry-run --force --delete --prune --verbose --set-upstream)
                   ;;
            esac
            ;;
      pull | fetch)
            case $wordNumber in
                2)
                    addRemoteNames
                    ;;
                3)
                    addRemoteBranchNames
                    ;;
                *)
                   if [ "$subcommand" == "pull" ]; then
                        options=(--ff --no-ff --ff-only --strategy)
                   elif [ "$subcommand" == "fetch" ]; then
                        options=(--all --dry-run --force --keep --prune --tags)
                   fi
                   ;;
            esac
            ;;
        rebase)
            case $wordNumber in
                2)
                    addLocalBranchNames
                    ;;
                *)
                   options=(--continue --abort --quit --skip --merge --strategy --quiet --verbose --force-rebase --interactive --autosquash)
                   ;;
            esac
            ;;
        remote)
            case $wordNumber in
                2)
                    options=(show add rm prune update)
                    ;;
                3)
                    addRemoteNames
                    options=(--verbose)
                    ;;
            esac
            ;;
        reset)
            addCommitShas 10
            addLocalBranchNames
            options=(HEAD --soft --mixed --hard --merge --keep)
            ;;
        show)
            addLocalBranchNames
            options=(--pretty --abbrev-commit --oneline --notes --show-notes --show-signature)
            ;;
        status)
            options=(--short --branch --show-stash --porcelain --long --verbose --untracked-files --ignore)
            ;;
        tag)
            case $wordNumber in
                2)
                    addTagNames
                    ;;
                3)
                    addLocalBranchNames
                    addCommitShas 10
                    ;;
            esac
            options=(--delete --force --list --annotate --sort --cleanup --message)
            ;;
    esac
        
    # remove repeated entries
    complete_tokens=($(echo "${complete_tokens[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))

    # combine tokens with sub-command options
    all_tokens=(${complete_tokens[@]} ${options[@]})
    
    # filter final results to ones matching the word being completed.
    final_tokens=()
    if [ "$word" == "" ]; then
        # no word prefix
        final_tokens=(${all_tokens[@]})
    else
        # filter results by word entered so far
        for token in "${all_tokens[@]}"; do
            if [[ $token == $word* ]]; then
                final_tokens+=($token)
            fi
        done
    fi
    
    if [ "$testMode" = true ]; then
        echo "============ INPUTS ============"
        echo "CMD '$command' SUB '$subcommand' WORD '$word'"
        echo ""
        echo "============ OPTIONS ==========="
        echo "${options[@]}"
        echo ""
        echo "============ TOKENS ============"
        echo "${complete_tokens[@]}"
        echo ""
        echo "============= FINAL ============"
    fi
    
    echo "${final_tokens[@]}"
}


doIt "$@"
