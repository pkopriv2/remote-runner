#! /bin/bash

require "lib/log.sh"
require "lib/dir.sh"

rr_key_home=${rr_key_home:-$rr_home/keys}
dir_create_if_missing "$rr_key_home"

# Generate a public/private key pair
# 
# @param name The name of the key pair [default="default"]
#
key_create() {
	local key_name=${1:-"default"}
	local key_file=$rr_key_home/id_rsa.$key_name
	if [[ -f $key_file ]]
	then
		log_error "Key pair [$key_name] already exist"
		exit 1
	fi

	log_info "Creating public/private key pair [$key_name]"

	local err=$(ssh-keygen -t rsa -f $key_file -N "" 2>&1 >/dev/null)
	if [[ $err  ]]
	then
		log_error "Error creating keys [$key_name]: $err"
		exit 1
	fi 

	log_info "Successfully created key [$key_name]"
}

# Get the value of a public key
#
# @param name The name of the key [default="default"]
key_get() {
	local key_name=${1:-"default"}
	local key_file=$rr_key_home/id_rsa.$key_name.pub
	if [[ ! -f $key_file ]]
	then
		log_error "Unable to locate public key [$key_file]"
		exit 1
	fi

	cat $key_file
}

# Get the value of a public key
#
# @param name The name of the key [default="default"]
key_delete() {
	local key_name=${1:-"default"}

	log_info "Deleting key [$key_name]"
	printf "%s" "Are you sure (y|n):"
	read answer

	if [[ "$answer" != "y" ]]
	then
		echo "Aborted."
		exit 0
	fi

	local key_file=$rr_key_home/id_rsa.$key_name
	if [[ ! -f $key_file ]]
	then
		log_error "Unable to locate public key [$key_file]"
		exit 1
	fi

	rm -f $key_file*
}

# Get a list of all the available keys
# 
#
key_list() {
	log_info "SSH Keys:"

	local list=($(builtin cd "$rr_key_home" ; find . -maxdepth 1 -mindepth 1 -name 'id_rsa.*.pub' -print | sed 's|\.\/id_rsa\.\([^\.]*\)\.pub|\1|' | sort ))
	for file in "${list[@]}"
	do
		echo "   - $file"
	done
}


key_help() {
	log_error "Undefined"
}

# Actually perform an action on the keys.
#
#
key_action() {
	args=($*)
	action="${args[0]}"
	unset args[0]

	case "$action" in
		list|get|create|delete)
			key_$action "${args[@]}"
			;;
		*)
			key_help
			exit 1
			;;
	esac
}
