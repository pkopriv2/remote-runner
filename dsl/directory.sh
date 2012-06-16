#! /bin/bash

directory() {
	if [[ -z $1 ]]
	then
		fail "Must supply a directory name."
	fi 

	log_info "Processing directory [$1]"

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

	if ! test -t 0
	then
		source /dev/stdin
	fi

	eval "path=$1"
	if ! su $owner -c "mkdir -p $path 1> /dev/null"
	then
		fail "Error creating directory [$path]"
	fi
}
