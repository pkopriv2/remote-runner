#! /bin/bash

archive_file() {
	log_info "Creating file [$1]"

	local src=""
	src() {
		src=$1
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

	# Download the file
	echo $src | nc $server_ip $fileserver_port > $1
	if (( $? )) 
	then
		log_error "Error downloading file [$1] and creating file [$1]"
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
}
