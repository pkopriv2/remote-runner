#! /bin/bash

require "host.sh"
require "role.sh"

source_host() {
	local key="default"
	key() {
		key=$1
	}

	local roles=()
	roles() {
		roles=($*)
	}

	if ! source $rr_host_home/$1.sh
	then
		log_error "Error sourcing host file [$host]"
		exit 1
	fi

	unset -f key
	unset -f roles

	attr() {
		attributes[$1]=$2
	}

	archives=()
	archives() {
		archives=( ${archives[*]} $* )
	}

	for role in "${roles[@]}"
	do
		if [[ ! -f $rr_role_home/$role.sh ]] 
		then
			log_error "Unable to determine run list for host [$1].  Role [$role] does not exist."
			exit 1
		fi 

		if ! source $rr_role_home/$role.sh
		then 
			log_error "Error sourcing role file [$role]: $err"
			exit 1
		fi
	done
}


