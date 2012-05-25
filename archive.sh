#! /bin/bash

require "lib/log.sh"
require "lib/dir.sh"

rr_archive_home=${rr_archive_home:-$rr_home/archives}
dir_create_if_missing "$rr_archive_home"


_archive_get_name() {
	if echo $1 | grep '::' &> /dev/null
	then
		echo $1 | sed 's|::.*$||'			
	else
		echo $1
	fi
}

_archive_get_script() {
	if echo $1 | grep '::' &> /dev/null
	then
		echo $1 | sed 's|^.*::||'
	else
		echo "default"
	fi
}

# Generate a archive.  An archive
# 
# @param name The name of the archive to create [default="default"]
archive_create() {
	local archive_name=${1:-"default"}
	local archive_file=$rr_archive_home/$archive_name.sh

	if [[ -f $archive_file ]]
	then
		log_error "archive [$archive_name] already exists"
		exit 1
	fi

	log_info "Creating archive [$archive_name]"
	touch $archive_file 
	log_info "Successfully created archive [$archive_name]"
}

# Get the value of a public archive
#
# @param name The name of the archive [default="default"]
archive_show() {
	local archive_name=${1:-"default"}
	local archive_file=$rr_archive_home/$archive_name.sh

	if [[ ! -f $archive_file ]]
	then
		log_error "archive [$archive_name] does not exist"
		exit 1
	fi

	cat $archive_file
}

# Get the value of a public archive
#
# @param name The name of the archive [default="default"]
archive_delete() {
	local archive_name=${1:-"default"}

	log_info "Deleting archive [$archive_name]"
	printf "%s" "Are you sure (y|n):"
	read answer

	if [[ "$answer" != "y" ]]
	then
		echo "Aborted."
		exit 0
	fi

	local archive_file=$rr_archive_home/$archive_name.sh
	if [[ ! -f $archive_file ]]
	then
		log_error "archive [$archive_name] does not exist"
		exit 1
	fi

	rm -f $archive_file
}

# Get a list of all the available archives
# 
# @param name The name of the archive [default="default"]
archive_list() {
	log_info "Archives:"

	local list=( $(builtin cd "$rr_archive_home" ; find . -maxdepth 1 -mindepth 1 -type d | sed 's|^\.\/||') )

	for file in "${list[@]}"
	do
		echo "   - $file"
	done
}

_archive_list() {
	local list=( $(builtin cd "$rr_archive_home" ; find . -maxdepth 1 -mindepth 1 -type d | sed 's|^\.\/||') )

	for file in "${list[@]}"
	do
		echo $file
	done
}


archive_help() {
	log_error "Undefined"
}

# Actually perform an action on the archives.
#
#
archive_action() {
	args=($*)
	action="${args[0]}"
	unset args[0]

	case "$action" in
		list|show|create|delete|edit)
			archive_$action "${args[@]}"
			;;
		*)
			archive_help
			exit 1
			;;
	esac
}
