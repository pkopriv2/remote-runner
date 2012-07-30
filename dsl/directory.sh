#! /bin/bash

require "lib/inode.sh"
require "dsl/includes/callbacks.sh"

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

	local group="$(user_get_primary_group $USER)"
	group() {
		group=$1
	}

	local permissions="755"
	permissions() {
		permissions=$1
	}

	# expand the path (a string isn't necessary a path)
	eval "local path=$1"

	# grab the std in.
	local block=$(cat -)
	eval "$block"

	if ! callback_on_condition
	then
		log_debug "Condition function not satisfied."
		return 0
	fi

	log_debug "Ensuring directory [$path] has ownership [$owner:$group] and permissions [$permissions]"

	local updated=false
	if [[ ! -d $path  ]] 
	then
		log_debug "That directory [$path] doesn't exist."
		if ! mkdir -p $mkdir -p $path 1> /dev/null
		then
			fail "Error creating directory [$path]"
		fi 

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
		callback_on_change 
	fi

	callback_on_success

}
