#! /bin/bash

directory() {
	log_info "Processing directory [$1]"

	local contents=""
	contents() {
		contents=$(cat)
	}

	local owner="$USER"
	owner() {
		owner=$1
	}

	local group="$USER"
	group() {
		group=$1
	}

	local permissions="644"
	permissions() {
		permissions=$1
	}

	if ! test -t 0
	then
		. /dev/stdin
	fi

	eval "path=$1"
	if ! mkdir -p $path 1> /dev/null
	then
		log_error "Error creating directory [$path]"
		exit 1
	fi

	if ! chown $owner:$group $path 
	then
		log_error "Error setting ownership of directory [$path]" 
		exit 1
	fi

	if ! chmod $permissions $path
	then
		log_error "Error setting permissions of directory [$path]"
		exit 1
	fi
}
