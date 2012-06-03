#! /bin/bash

nc_cmds=( nc.traditional )
for cmd in "${nc_cmds[@]}"
do
	if command -v $cmd &> /dev/null
	then
		nc_cmd=$cmd
	fi
done

if  [[ -z $nc_cmd ]]
then
	case $distro in
		Ubuntu|Debian)
			package_require "netcat-traditional" 
			;;
		*)
			log_error "Unable to install netcat.  This will cause attempts to call archive_file to fail."
	esac 
fi

archive_file() {
	if  [[ -z $nc_cmd ]]
	then
		fail "Unable to locate netcat."
	fi

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

	local permissions="644"
	permissions() {
		permissions=$1
	}

	. /dev/stdin

	eval "path=$1"
	log_debug "Path has expanded to: [$path]"

	echo "$archive_name::$src" | $nc_cmd $server_ip $fileserver_port > $path
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
