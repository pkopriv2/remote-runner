#! /bin/bash

require "local/log.sh"
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

#
#
#
archive_install() {
	if [[ ! -d $1 ]]
	then
		error "Archive [$1] doesn't exist."
		exit 1
	fi 

	path=$(builtin cd $1; pwd)
	info "Installing archive [$path]."

	#if ! ln -s $path $rr_archive_home
	#then
		#error "Error installing archive [$1]."
		#exit 1
	#fi 
	
	#info "Successfully installed archive [$!]"
}

# Generate a archive in the current working directory.
# The following structure will be made:
# 
# @param name The name of the archive to create
archive_create() {
	if [[ -z $1 ]]
	then
		error "Must supply an archive name."
		exit 1
	fi

	info "Creating archive [$1]"
	mkdir $1
	mkdir $1/files
	mkdir $1/scripts
	touch $1/scripts/default.sh
	info "Successfully created archive [$1]"
}

# Get the value of a public archive
#
# @param name The name of the archive [default="default"]
archive_delete() {
	if [[ -z $1 ]]
	then
		error "Must supply an archive name."
		exit 1
	fi

	archive=$rr_archive_home/$1
	if [[ ! -d $archive ]]
	then
		error "Archive [$archive] doesn't exist."
		exit 1
	fi

	info "Deleting archive [$archive]"
	printf "%s" "Are you sure (y|n):"
	read answer

	if [[ "$answer" != "y" ]]
	then
		echo "Aborted."
		exit 0
	fi

	rm -fr $archive
}

# Get a list of all the installed archives
# 
# @param name The name of the archive [default="default"]
archive_list() {
	info "Archives:"

	local list=( $(_archive_list) )

	for file in "${list[@]}"
	do
		echo "   - $file"
	done
}

_archive_list() {
	local list=( $(builtin cd "$rr_archive_home" ; find . -maxdepth 1 -mindepth 1 | sed 's|^\.\/||' | sort ) )

	for e in "${list[@]}"
	do
		if [[ -d $rr_archive_home/$e ]] || [[ -h $rr_archive_home/$e ]]
		then
			echo "$e"
		fi
	done
}


archive_help() {
	error "Undefined"
}

# Actually perform an action on the archives.
#
#
archive_action() {
	args=($*)
	action="${args[0]}"
	unset args[0]

	case "$action" in
		list|show|create|delete|edit|install)
			archive_$action "${args[@]}"
			;;
		*)
			archive_help
			exit 1
			;;
	esac
}
