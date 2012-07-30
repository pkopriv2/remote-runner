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
		if [[ -z $1 ]] 
		then
			contents=$(cat -)
			return 0 
		fi
		
		contents="$1"
	}

	template() {
		log_debug "Creating file [$1] from template: $template_src"

		local template_file=$rr_home_remote/archives/$archive_name/templates/$template_src 
		if [[ ! -f $template_file ]]
		then
			fail "Template [$template_src] does not exist in archive [$archive_name]"
		fi 

		contents=$(ebash_process_file $template_file $path) 
	}

	src() {
		log_debug "Creating file [$1] from archive file: $file_src"

		local file=$rr_home_remote/archives/$archive_name/files/$file_src
		if [[ ! -f $file ]]
		then
			fail "Archive file [$file_src] does not exist in archive [$archive_name]"
		fi 

		local contents=$(cat $file) 
	}

	eval "local path=$1"

	# grab the std in.
	local block=$(cat -)
	eval "$block"

	if ! on_condition_func 
	then
		log_debug "Condition function not satisfied."
		return 0
	fi

	if [[ -f $path ]]
	then
		local cur_contents=$(cat $path)
	else
		local cur_contents=""
	fi

	local cur_hash=$(echo "$cur_contents" | md5sum | awk '{print $1}')
	local new_hash=$(echo "$contents" | md5sum | awk '{print $1}')

	if [[ "$cur_hash" != "$new_hash" ]]
	then
		log_debug "New hash [$new_hash] differs from current hash [$cur_hash]"
		echo "$contents" > $path
		local updated=true
	fi

	if ! inode_has_owner? $path $owner || ! inode_has_group? $path $group 
	then
		log_debug "That directory [$path] has different ownership."
		if ! chown $owner:$group $path 1>/dev/null 
		then
			fail "Error setting ownership [$owner:$group] of directory [$path]"
		fi 

		local updated=true
	fi

	if ! inode_has_permissions? $path $permissions
	then
		log_debug "That directory [$path] has different permissions."
		if ! chmod $permissions $path 1>/dev/null 
		then
			fail "Error setting permissions [$permissions] of directory [$path]"
		fi

		local updated=true
	fi

	if $updated
	then
		on_change_func 
	fi
}
