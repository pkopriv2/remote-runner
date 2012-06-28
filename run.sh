#! /bin/bash

set -a 

declare -A attributes

# Determines the host environment.  This will set the following
# global variables:
# 	- key
#   - roles
# 
# @param 1 - The host environment to source
#
_source_host() {
	log_info "Sourcing host environment: $1"

	key="default"
	key() {
		key=${1:-"default"}
	}

	roles=()
	roles() {
		roles+=( $* )
	}

	if [[ ! -f $rr_host_home/$1.sh ]] 
	then
		fail "Host file [$1] does not exist."
	fi 

	if ! source $rr_host_home/$1.sh
	then
		fail "Error sourcing host file [$host]"
	fi

	roles=( $(array_uniq "${roles[@]}") )

	unset -f key
	unset -f roles
}

# Given a list of roles, this method will source
# all the role files and upadate the following global
# attributes:
#
#   - attributes
# 	- archives
# 
# @param 1..n - The roles to source.
#
_source_roles() {
	attributes=()
	attr() {
		attributes+=(["$1"]=$2)
	}

	archives=()
	archives() {
		archives+=( $* )
	}

	for role in "${@}"
	do
		if [[ ! -f $rr_role_home/$role.sh ]] 
		then
			fail "Unable to determine run list for host [$1].  Role [$role] does not exist."
		fi 

		if ! source $rr_role_home/$role.sh
		then 
			fail "Error sourcing role file [$role]: $err"
		fi
	done

	archives=( $(array_uniq "${archives[@]}") )

	unset -f attr
	unset -f archives 
}

# Given a key name determine the keyfile and
# add it to the ssh connection agent. This
# will set the following global attributes:
#
# 	- key_file
#
# @param 1 - The name of the key
#
_source_key() {
	key_file=$rr_key_home/id_rsa.$key

	if [[ ! -f $key_file ]] 
	then 
		fail "That key file [$key_file] doesn't exist!"
	fi
	
	if ! ssh-add $key_file
	then
		fail "Unable to source the key file [$key_file]"
	fi 
}

_create_std_lib() {

}

_create_lib() {
	local host=$1
	local key_file=$2
	local archives=( ${@:3} )

	log_info "Building archive library from archives: $(array_print ${archives[@]})"


}


run_help() {
	info "** Host Commands **"
	echo 

	methods=( list )
	for method in "${methods[@]}" 
	do
		echo "rr host $method [options]"
	done

	methods=( bootstrap show edit )
	for method in "${methods[@]}" 
	do
		echo "rr host $method [options] [HOST]"
	done
}


run_action() {
	args=($*)
	action="${args[0]}"
	unset args[0]

	case "$action" in
		list|bootstrap|show|edit)
			host_$action "${args[@]}"
			;;
		*)
			host_help
			exit 1
			;;
	esac
}
