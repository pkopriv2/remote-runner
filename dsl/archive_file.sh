#! /bin/bash

nc_cmd=${nc_cmd:-nc}
if command -v nc.traditional $> /dev/null
then
	nc_cmd=nc.traditional
fi


archive_file() {
	if [[ -z $1 ]]
	then
		log_error "Must supply a file name."
		exit 1 
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
	owner() {
		owner=$1
	}

	local permissions="644"
	permissions() {
		permissions=$1
	}

	. /dev/stdin

	eval "path=$1"
	echo $src | $nc_cmd $server_ip $fileserver_port > $path
	if (( $? )) 
	then
		log_error "Error downloading file [$src] and creating file [$1]"
		exit 1
	fi

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
