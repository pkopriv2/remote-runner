#! /bin/bash

# Provides a useful dsh method that will easily create
#

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
	owner() {
		owner=$1
	}

	local permissions="644"
	permissions() {
		permissions=$1
	}

	. /dev/stdin

	if ! touch $1 1> /dev/null
	then
		log_error "Error creating file [$1]"
		exit 1
	fi

	if ! chown $owner:$group $1 
	then
		log_error "Error setting ownership of file [$1]" 
		exit 1
	fi

	if ! chmod $permissions $1
	then
		log_error "Error setting permissions of file [$1]"
		exit 1
	fi

	echo "$contents" | cat > $1
}
