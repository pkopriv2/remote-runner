#! /bin/bash

require "lib/msg.sh"
require "lib/dir.sh"

rr_role_home=${rr_role_home:-$rr_home/roles}
dir_create_if_missing "$rr_role_home"

declare -A attributes

# Given a list of roles, this method will source
# all the role files and upadate the following global
# attributes:
#
#   - attributes
# 	- archives
# 
# @param 1..n - The roles to source.
#
_source_roles() {
	attributes=()
	attr() {
		attributes+=(["$1"]=$2)
	}

	archives=()
	archives() {
		archives+=( $* )
	}

	for role in "${@}"
	do
		if [[ ! -f $rr_role_home/$role.sh ]] 
		then
			fail "Unable to determine run list for host [$1].  Role [$role] does not exist."
		fi 

		source $rr_role_home/$role.sh
	done

	archives=( $(array_uniq "${archives[@]}") )

	unset -f attr
	unset -f archives 
}

# Generate a role file
# 
# @param name The name of the role to create [default="default"]
#
role_create() {
	local role_name=${1:-"default"}
	local role_file=$rr_role_home/$role_name.sh

	if [[ -f $role_file ]]
	then
		error "Role [$role_name] already exists"
		exit 1
	fi

	info "Creating role [$role_name]"
	if touch $role_file
	then
		info "Successfully created role [$role_name]"
	else
		error "Error creating role [$role_name]"
	fi
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
		error "Role [$role_name] does not exist"
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
		error "Role [$role_name] does not exist"
		exit 1
	fi

	cat $role_file
}

# Get the value of a public role
#
# @param name The name of the role [default="default"]
role_delete() {
	local role_name=${1:-"default"}

	info "Deleting role [$role_name]"
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
		error "Role [$role_name] does not exist"
		exit 1
	fi

	rm -f $role_file
}

# Get a list of all the available roles
# 
# @param name The name of the role [default="default"]
role_list() {
	info "Roles:"

	local list=($(builtin cd "$rr_role_home" ; find . -maxdepth 1 -mindepth 1 -name '*.sh' -print | sed 's|\.\/||' | sed 's|\.sh||' | sort ))

	for file in "${list[@]}"
	do
		echo "   - $file"
	done
}


role_help() {
	info "** Role Commands **"
	echo 

	methods=( list create )
	for method in "${methods[@]}" 
	do
		echo "rr role $method [options]*"
	done

	methods=( show edit delete )
	for method in "${methods[@]}" 
	do
		echo "rr role $method [options]* [ROLE]"
	done
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
