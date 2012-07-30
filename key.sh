#! /bin/bash

require "lib/dir.sh"
require "lib/msg.sh"

rr_key_home=${rr_key_home:-$rr_home/keys}
dir_create_if_missing "$rr_key_home"

# Given a key name determine the keyfile and
# add it to the ssh connection agent. This
# will set the following global attributes:
#
# 	- key_file
#
# @param 1 - The name of the key
#
_source_key() {
	key_file=$rr_key_home/id_rsa.$1

	if [[ ! -f $key_file ]] 
	then 
		fail "That key file [$key_file] doesn't exist!"
	fi
	
	if ! ssh-add $key_file &> /dev/null
	then
		fail "Unable to source the key file [$key_file]"
	fi 
}

# Generate a public/private key pair
# 
# @param $1 The name of the key pair [default="default"]
#
key_create() {
	local key_name=${1:-"default"}
	local key_file=$rr_key_home/id_rsa.$key_name
	if [[ -f $key_file ]]
	then
		error "Key pair [$key_name] already exist"
		exit 1
	fi

	info "Creating public/private key pair [$key_name]"

	printf "%s" "Enter a passphrase:"
	read -s passphrase
	echo

	local err=$(ssh-keygen -t rsa -f $key_file -N "$passphrase" 2>&1 >/dev/null)
	if [[ $err  ]]
	then
		error "Error creating keys [$key_name]: $err"
		exit 1
	fi 

	info "Successfully created key [$key_name]"
}

# Get the value of a public key
#
# @param name The name of the key [default="default"]
key_show() {
	local key_name=${1:-"default"}
	local key_file=$rr_key_home/id_rsa.$key_name.pub
	if [[ ! -f $key_file ]]
	then
		error "Unable to locate public key [$key_file]"
		exit 1
	fi

	cat $key_file
}

# Get the value of a public key
#
# @param name The name of the key [default="default"]
key_delete() {
	local key_name=${1:-"default"}

	info "Deleting key [$key_name]"
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
		error "Unable to locate public key [$key_file]"
		exit 1
	fi

	rm -f $key_file*
}

# Get a list of all the available keys
# 
#
key_list() {
	info "SSH Keys:"

	local list=($(builtin cd "$rr_key_home" ; find . -maxdepth 1 -mindepth 1 -name 'id_rsa.*.pub' -print | sed 's|\.\/id_rsa\.\([^\.]*\)\.pub|\1|' | sort ))
	for file in "${list[@]}"
	do
		echo "   - $file"
	done
}

key_home() {
	info "Key home: $rr_key_home"
}


key_help() {
	info "** Key Commands **"
	echo 

	methods=( list create )
	for method in "${methods[@]}" 
	do
		echo "rr key $method [options]*"
	done

	methods=( show delete )
	for method in "${methods[@]}" 
	do
		echo "rr key $method [options]* [KEY]"
	done
}

# Actually perform an action on the keys.
#
#
key_action() {
	args=($*)
	action="${args[0]}"
	unset args[0]

	case "$action" in
		list|show|create|delete|home)
			key_$action "${args[@]}"
			;;
		*)
			key_help
			exit 1
			;;
	esac
}
