#! /bin/bash

require "lib/fail.sh"

rr_home_remote=${rr_home_remote:-/tmp/rr}
rr_esh_delimiter=${rr_esh_delimiter:-"--"}


template() {
	if [[ -z $archive_name ]]
	then
		fail "Unknown archive."
	fi 

	if [[ -z $1 ]]
	then
		fail "Must supply a file name."
	fi 

	log_info "Processing template [$1]"

	local src=""
	src() {
		src=$1
	}

	local owner="$USER"
	owner() {
		owner=$1
	}

	local group="$USER"
	group() {
		group=$1
	}

	local permissions="755"
	permissions() {
		permissions=$1
	}

	if test -t 0
	then
		fail "Must provide at least provide a template src"
	fi

	source /dev/stdin

	eval "path=$1"
	log_debug "Path has expanded to: $path"

	local template=$rr_home_remote/$archive_name/templates/$src
	log_debug  "Retrieving template from: $template"

	if [[ ! -f $template ]]
	then
		fail "Template [$src] does not exist in archive [$archive_name]"
	fi 

	_process_template $template > $path

	if ! chown $owner:$group $path 
	then
		log_error "Error setting ownership of file [$1]" 
		exit 1
	fi

	if ! chmod $permissions $path
	then
		log_error "Error setting permissions of file [$1]"
		exit 1
	fi
}
