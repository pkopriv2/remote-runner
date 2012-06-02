#! /bin/bash

file() {
	log_info "Creating file [$1]"

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
	if ! touch $path 1> /dev/null
	then
		log_error "Error creating file [$path]"
		exit 1
	fi

	if ! chown $owner:$group $path 
	then
		log_error "Error setting ownership of file [$path]" 
		exit 1
	fi

	if ! chmod $permissions $path
	then
		log_error "Error setting permissions of file [$path]"
		exit 1
	fi

	echo "$contents" | cat > $path
}
