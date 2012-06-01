#! /bin/bash

rr_home=${rr_home:-$HOME/.rr}
rr_archive_home=${rr_archive_home:-$rr_home/archives}
rr_host_home=${rr_host_home:-$rr_home/hosts}
rr_key_home=${rr_key_home:-$rr_home/keys}
rr_role_home=${rr_role_home:-$rr_home/roles}

. $rr_home/local/msg.sh 

rrcd() {
	if [[ -z $1 ]]
	then
		error "Must supply an archive name."
		return 1
	fi

	if [[ ! -d $rr_archive_home/$1 ]]
	then
		error "Archive [$1] doesn't exist."
		return 1
	fi 
	
	builtin cd $rr_archive_home/$1
	info "$(pwd)"
}
