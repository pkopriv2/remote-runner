#! /bin/bash

require "local/log.sh"
require "lib/dir.sh"

rr_role_home=${rr_role_home:-$rr_home/roles}
dir_create_if_missing "$rr_role_home"

# Generate a role file
# 
# @param name The name of the role to create [default="default"]
#
role_create() {
	local role_name=${1:-"default"}
	local role_file=$rr_role_home/$role_name.sh

	if [[ -f $role_file ]]
	then
		log_error "Role [$role_name] already exists"
		exit 1
	fi

	log_info "Creating role [$role_name]"
	touch $role_file 
	log_info "Successfully created role [$role_name]"
}

# Edit a role file with the environment $EDITOR program
# 
# @param name The name of the role to edit [default="default"]
#
role_edit() {
	local role_name=${1:-"default"}
	local role_file=$rr_role_home/$role_name.sh

	if [[ ! -f $role_file ]]
	then
		log_error "Role [$role_name] does not exist"
		exit 1
	fi

	${EDITOR:-"vim"} $role_file
}

# Get the value of a public role
#
# @param name The name of the role [default="default"]
role_show() {
	local role_name=${1:-"default"}
	local role_file=$rr_role_home/$role_name.sh

	if [[ ! -f $role_file ]]
	then
		log_error "Role [$role_name] does not exist"
		exit 1
	fi

	cat $role_file
}

# Get the value of a public role
#
# @param name The name of the role [default="default"]
role_delete() {
	local role_name=${1:-"default"}

	log_info "Deleting role [$role_name]"
	printf "%s" "Are you sure (y|n):"
	read answer

	if [[ "$answer" != "y" ]]
	then
		echo "Aborted."
		exit 0
	fi

	local role_file=$rr_role_home/$role_name.sh
	if [[ ! -f $role_file ]]
	then
		log_error "Role [$role_name] does not exist"
		exit 1
	fi

	rm -f $role_file
}

# Get a list of all the available roles
# 
# @param name The name of the role [default="default"]
role_list() {
	log_info "Roles:"

	local list=($(builtin cd "$rr_role_home" ; find . -maxdepth 1 -mindepth 1 -name '*.sh' -print | sed 's|\.\/||' | sed 's|\.sh||' | sort ))

	for file in "${list[@]}"
	do
		echo "   - $file"
	done
}


role_help() {
	log_error "Undefined"
}

# Actually perform an action on the roles.
#
#
role_action() {
	args=($*)
	action="${args[0]}"
	unset args[0]

	case "$action" in
		list|show|create|delete|edit)
			role_$action "${args[@]}"
			;;
		*)
			role_help
			exit 1
			;;
	esac
}
