#! /bin/bash

require "lib/ebash.sh"

file() {
	log_info "Creating file [$1]"

	local owner="$USER"
	owner() {
		owner=$1
	}

	local group="$(user_get_primary_group $USER)"
	group() {
		group=$1
	}

	local permissions="644"
	permissions() {
		permissions=$1
	}

	declare contents
	contents() {
		if ! test -t 0
		then
			contents=$(cat -)
			return 0 
		fi
		
		contents="$1"
	}

	declare template_src
	template() {
		template_src="$1"
	}

	declare file_src
	src() {
		file_src="$1"
	}

	if ! test -t 0
	then
		. /dev/stdin
	fi

	eval "path=$1"
	log_debug "Path has expanded to: $path"

	if [[ ! -z $template_src ]]
	then
		log_debug "Creating file [$1] from template: $template_src"

		local template_file=$rr_home_remote/archives/$archive_name/templates/$template_src 
		if [[ ! -f $template_file ]]
		then
			fail "Template [$template_src] does not exist in archive [$archive_name]"
		fi 

		ebash_process_file $template_file > $path

	elif [[ ! -z $file_src ]]
	then
		log_debug "Creating file [$1] from archive file: $file_src"

		local file=$rr_home_remote/archives/$archive_name/files/$file_src
		if [[ ! -f $file ]]
		then
			fail "Archive file [$file_src] does not exist in archive [$archive_name]"
		fi 

		cp $file $path || fail "Error creating file: $path"

	else
		log_debug "Processing file from contents."
		echo "$contents" > $path
	fi

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
}
