#! /bin/bash

rr_home_remote=${rr_home_remote:-/tmp/rr}

archive_file() {
	if [[ -z $archive_name ]]
	then
		fail "Unknown archive."
	fi 

	if [[ -z $1 ]]
	then
		fail "Must supply a file name."
	fi 

	log_info "Processing archive_file file [$1]"

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

	. /dev/stdin

	eval "path=$1"
	log_debug "Path has expanded to: [$path]"

	local file=$rr_home_remote/$archive_name/files/$src
	log_debug "Retrieving file from: $file"

	if [[ ! -f $file ]]
	then
		fail "Archive file [$src] does not exist in archive [$archive_name]"
	fi 

	cp $file $path || fail "Error creating file: $path"

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
