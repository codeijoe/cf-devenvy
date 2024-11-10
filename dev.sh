#!/usr/bin/env bash

# Cloudflare Development Environment 
# DX on-top of Docker.
# 
# command:
# - `build-envy`
# - `start-envy $WORKSPACE`


# DESC: Define Script Debugging
# Enable xtrace if the DEBUG environment variable is set
if [[ ${DEBUG-} =~ ^1|yes|true$ ]]; then
    set -o xtrace       # Trace the execution of the script (debug)
fi

# Only enable these shell behaviours if we're not being sourced
# Approach via: https://stackoverflow.com/a/28776166/8787985
if ! (return 0 2> /dev/null); then
    # A better class of script...
    set -o errexit      # Exit on most errors (see the manual)
    set -o nounset      # Disallow expansion of unset variables
    set -o pipefail     # Use last non-zero exit code in a pipeline
fi

# Enable errtrace or the error trap handler will not work as expected
set -o errtrace         # Ensure the error trap handler is inherited


# DESC: Define Executables
dc=$(which docker)
dcom=$(which docker-compose)
ACT_BUILD=false
ACT_RUN=false


# DESC: Define Common Vars 
LANG=en_US.UTF-8
LANGUAGE=en_US:en
LC_ALL=en_US.UTF-8
FORCE_COLOR=0
NO_COLOR=1
OSVERSION=$(uname)

# DESC: Define DEVENVY Vars 
DEVENVY_WORKSPACE=default
DEVENVY_BUILDER=default

# DESC: Import external .env file to script
# ARGS: None
# OUTS: None
# RETS: None
# tools: 
#   - grep -F -- "DEVENVY_PORT" env-example | cut -d'=' -f2
function act_import_env() {
    DEVENVY_BUILDER=$(grep -F -- "DEVENVY_BUILDER" .env | cut -d'=' -f2)
    DEVENVY_WORKSPACE=$(grep -F -- "DEVENVY_WORKSPACE" .env | cut -d'=' -f2)
}

# DESC: Build CF Devenvy Docker Images
# ARGS: $1 (optional): Tags:Version
# OUTS: None
# RETS: None
function act_build_image() {
    local args=0
    if [[ $args -eq 0 ]] ; then
        $dcom build 
    else
        #with args
        $dcom build --build-arg $args --no-cache
    fi
    # $dc tag devenvy:v0.0 $DEVENVY_IMAGE:$DEVENVY_TAG
    # $dc version
    # $dcom version
    # echo "System: $OSVERSION"
}

# DESC: Run CF Devenvy Docker Container
# ARGS: $1 (optional): Exit code (defaults to 1)
# OUTS: None
# RETS: None
function act_run_image() {
    echo "System: $OSVERSION"
    echo "Args: $1"
}

# DESC: Generic script initialisation
# ARGS: $@ (optional): Arguments provided to the script
# OUTS: $orig_cwd: The current working directory when the script was run
#       $script_path: The full path to the script
#       $script_dir: The directory path of the script
#       $script_name: The file name of the script
#       $script_params: The original parameters provided to the script
#       $ta_none: The ANSI control code to reset all text attributes
# RETS: None
# NOTE: $script_path only contains the path that was used to call the script
#       and will not resolve any symlinks which may be present in the path.
#       You can use a tool like realpath to obtain the "true" path. The same
#       caveat applies to both the $script_dir and $script_name variables.
# shellcheck disable=SC2034
function script_init() {
    # Useful variables
    readonly orig_cwd="$PWD"
    readonly script_params="$*"
    readonly script_path="${BASH_SOURCE[0]}"
    script_dir="$(dirname "$script_path")"
    script_name="$(basename "$script_path")"
    readonly script_dir script_name

    # Important to always set as we use it in the exit handler
    # shellcheck disable=SC2155
    readonly ta_none="$(tput sgr0 2> /dev/null || true)"
}

# DESC: Handler for unexpected errors
# ARGS: $1 (optional): Exit code (defaults to 1)
# OUTS: None
# RETS: None
function script_trap_err() {
    local exit_code=1

    # Disable the error trap handler to prevent potential recursion
    trap - ERR

    # Consider any further errors non-fatal to ensure we run to completion
    set +o errexit
    set +o pipefail

    # Validate any provided exit code
    if [[ ${1-} =~ ^[0-9]+$ ]]; then
        exit_code="$1"
    fi

    # Output debug data if in Cron mode
    if [[ -n ${cron-} ]]; then
        # Restore original file output descriptors
        if [[ -n ${script_output-} ]]; then
            exec 1>&3 2>&4
        fi

        # Print basic debugging information
        printf '%b\n' "$ta_none"
        printf '***** Abnormal termination of script *****\n'
        printf 'Script Path:            %s\n' "$script_path"
        printf 'Script Parameters:      %s\n' "$script_params"
        printf 'Script Exit Code:       %s\n' "$exit_code"

        # Print the script log if we have it. It's possible we may not if we
        # failed before we even called cron_init(). This can happen if bad
        # parameters were passed to the script so we bailed out very early.
        if [[ -n ${script_output-} ]]; then
            # shellcheck disable=SC2312
            printf 'Script Output:\n\n%s' "$(cat "$script_output")"
        else
            printf 'Script Output:          None (failed before log init)\n'
        fi
    fi

    # Exit with failure status
    exit "$exit_code"
}

# DESC: Handler for exiting the script
# ARGS: None
# OUTS: None
# RETS: None
function script_trap_exit() {
    cd "$orig_cwd"

    # Remove Cron mode script log
    if [[ -n ${cron-} && -f ${script_output-} ]]; then
        rm "$script_output"
    fi

    # Remove script execution lock
    if [[ -d ${script_lock-} ]]; then
        rmdir "$script_lock"
    fi

    # Restore terminal colours
    printf '%b' "$ta_none"
}

# DESC: Exit script with the given message
# ARGS: $1 (required): Message to print on exit
#       $2 (optional): Exit code (defaults to 0)
# OUTS: None
# RETS: None
# NOTE: The convention used in this script for exit codes is:
#       0: Normal exit
#       1: Abnormal exit due to external error
#       2: Abnormal exit due to script error
function script_exit() {
    if [[ $# -eq 1 ]]; then
        printf '%s\n' "$1"
        exit 0
    fi

    if [[ ${2-} =~ ^[0-9]+$ ]]; then
        printf '%b\n' "$1"
        # If we've been provided a non-zero exit code run the error trap
        if [[ $2 -ne 0 ]]; then
            script_trap_err "$2"
        else
            exit 0
        fi
    fi

    script_exit 'Missing required argument to script_exit()!' 2
}

# DESC: Usage build
# ARGS: tags,version
# OUTS: None
# RETS: None
function script_usage() {
    cat << EOF
Cloudflare Development Environment.
Version 0.1
DEBUG=[yes/no] [shell] dev.sh [options]

Usage:
     -h|--help                  Displays this help
     -v|--verbose               Displays verbose output
     -b|--build                 Build devenvy image
     -r|--run                   Run devenvy container

example:
> DEBUG=no bash dev.sh -b

EOF
}

# DESC: Parameter parser
# ARGS: $@ (optional): Arguments provided to the script
# OUTS: Variables indicating command-line parameters and options
# RETS: None
function parse_params() {
    local param
    local args=0
    if [[ $# -eq 0 ]] then 
        script_usage
    fi
    while [[ $# -gt 0 ]]; do
        param="$1"
        if [ $# -eq 2 ]; then
            args="$2"
            shift 2
        else
            shift
        fi
        case $param in
            -h | --help)
                script_usage
                exit 0
                ;;
            -v | --verbose)
                verbose=true
                ;;
            -b | --build)
                if [[ $args -eq 0 ]]; then
                    act_build_image
                else
                    act_build_image $args
                fi
                ;;
            -r | --run)
                act_run_image "run $args"
                ;;
            *)
                script_exit "Invalid parameter was provided: $param" 1
                ;;
        esac
    done
}

# DESC: Main control flow
# ARGS: $@ (optional): Arguments provided to the script
# OUTS: None
# RETS: None
function main() {
    trap script_trap_err ERR
    trap script_trap_exit EXIT

    script_init "$@"
    act_import_env
    parse_params "$@"
}


# Invoke main with args if not sourced
if ! (return 0 2> /dev/null); then
    main "$@"
fi

# vim: syntax=sh cc=80 tw=79 ts=4 sw=4 sts=4 et sr
