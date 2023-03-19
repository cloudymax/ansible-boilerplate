#!/bin/bash
set -Eeuo pipefail

export DEBUG="false"
export INVENTORY="none"
export ANSIBLE_USER="none"
export PROFILE="none"
export ANSIBLE_NOCOWS=1
export ANSIBLE_COW_SELECTION="none"
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export NC='\033[0m'

[[ ! -x "$(command -v date)" ]] && echo "💥 date command not found." && exit 1

# Parse command line args and set flags accordingly
parse_params() {
        while :; do
                case "${1-}" in
                -h | --help) usage ;;
                -v | --verbose) set -x ;;
                -d | --debug) DEBUG="true";;
                -c | --cows)
                        ANSIBLE_COW_SELECTION="${2-}"
                        shift
                        ;;
                -p | --profile)
                        PROFILE="${2-}"
                        shift
                        ;;
                -au | --ansible-user)
                        ANSIBLE_USER="${2-}"
                        shift
                        ;;
                -i | --inventory-file)
                        INVENTORY="${2-}"
                        shift
                        ;;
                -?*) die "Unknown option: $1" ;;
                *) break ;;
                esac
                shift
        done

        log "⏰ Starting up..."
        log "📋 Setting variables"

        if [ "$DEBUG" == "false" ]; then
           log "🔎 DEBUG not set." 
           log "   $GREEN  ➡️ Defaulting to 'False' $NC"
        fi

        if [ "$INVENTORY" == "none" ]; then
           log "🔎 No inventory specified"
           log "   $GREEN  ➡️ asumming localhost. $NC"
        else
            if [[ -f "$INVENTORY" ]]; then
                log "✅ $INVENTORY exists. Continuing."
            else
                log "💥 $INVENTORY does not exist."
                exit
            fi
        fi

        if [ "$ANSIBLE_USER" == "none" ]; then
           log "💥 No ansible user specified"
           export ANSIBLE_USER="$USER"
           #log "   $GREEN  ➡️ set ansible user to $ANSIBLE_USER. $NC"
        fi
        
        if [ "$PROFILE" == "none" ]; then
           log "🔎 No profile selected."
           log "   $GREEN  ➡️ Defaulting to 'basic_desktop' $NC"
           export PROFILE="basic_desktop"
        else
           export PROFILE="$PROFILE"
        fi
        
        if [ "$ANSIBLE_COW_SELECTION" == "none" ]; then
           log "🐄 No cowsay charcter specified"
           log "   $RED  ➡️ disabling cows. $NC"
           ANSIBLE_NOCOWS=1
        else
           ANSIBLE_NOCOWS=0
        fi
        main
}

# help text
usage() {
        cat <<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-c cow_name] [-p /path/to/profile] [-au ansible-user] [-i /path/to/inventory] [-d] 

💁 This script will execute an ansible role that loops over a yaml file, 
   and performs the defined actions.

Available options:

-c, --cows              select a cow to use for cowsay

-p, --profile           Path to the ansible profile directory.

-au, --ansible-user     The user account that Ansible will use to execute tasks

-i, --inventory-file    Path to Ansible inventory file

-d, --debug             print ansibke debug text

EOF
        exit
}

# Logging method
log() {
        echo >&2 -e "[$(date +"%Y-%m-%d %H:%M:%S")] ${1-}"
}

# kill on error
die() {
        local MSG=$1
        local CODE=${2-1} # Bash parameter expansion - default exit status 1. See https://wiki.bash-hackers.org/syntax/pe#use_a_default_value
        log "${MSG}"
        exit "${CODE}"
}

main() {
    # Profile to use for demo (absolute path)
    USER=$(whoami)
    export DEMO_DIR="ansible_profiles/$PROFILE"
    export ANSIBLE_PLAYBOOK="main-program.yaml"

    # Program verbosity
    export VERBOSITY="-v"
    export DEBUG="true"
    export SQUASH="false"

    for file in "${DEMO_DIR}"/*.yaml
    do
        echo "running $file ..."
        docker run --platform linux/amd64 -it \
            -v $(pwd):/ansible \
            -v $(pwd)/test/friend:/id_rsa \
            -e ARA_API_SERVER="http://192.168.50.100:8000" \
            -e ARA_API_CLIENT="http" \
            ansible-runner ansible-playbook playbooks/main-program.yaml \
            -i sample-inventory.yaml \
            --extra-vars="ansible_ssh_user=testadmin" \
            --extra-vars="ansible_user=testadmin" \
            --extra-vars="ansible_ssh_private_key_file=test/friend" \
            --extra-vars="profile_path=/ansible/${file}" \
            --extra-vars="profile_dir=ansible_profiles/basic_desktop" \
            --extra-vars="squash=${SQUASH}" \
            --extra-vars="debug_output=${DEBUG}" \
            "$VERBOSITY"
    done
}

parse_params "$@"
