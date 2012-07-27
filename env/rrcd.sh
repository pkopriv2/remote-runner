#! /bin/bash

rr_home=${rr_home:-$HOME/.rr}

source $rr_home/require.sh

require "lib/msg.sh"

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
