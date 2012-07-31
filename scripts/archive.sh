#! /bin/bash

export rr_archive_home

require "lib/msg.sh"
require "lib/dir.sh"
require "lib/fail.sh" 

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

archive_install() {
	if [[ -z $1 ]]
	then
		error "Must supply an archive name."
		exit 1
	fi

	if [[ ! -d $1 ]]
	then
		error "Directory [$1] doesn't exist."
		exit 1
	fi 
	
	info "Installing archive [$1]."

	path=$(builtin cd $1; pwd)

	if ! ln -s $path $rr_archive_home &> /dev/null
	then
		error "Error installing archive [$1]."
		exit 1
	fi 
	
	info "Successfully installed archive [$1]"
}

archive_create() {
	if [[ -z $1 ]]
	then
		error "Must supply an archive name."
		exit 1
	fi

	local output_dir=$(pwd)
	while getopts ":o" opt 
	do
		case $opt in
			o)
				output_dir=$OPTARG
		esac 
	done

	info "Creating archive [$1]"

	if ! mkdir $output_dir/$1 &> /dev/null \
	|| ! mkdir $output_dir/$1/files &> /dev/null \
	|| ! mkdir $output_dir/$1/scripts &> /dev/null \
	|| ! touch $output_dir/$1/scripts/default.sh &> /dev/null
	then 
		error "Error creating archive [$1]."
		exit 1
	fi

	info "Successfully created archive [$1]"
}

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

	if [[ -h $archive ]]
	then
		rm -fr $(readlink $archive)
	else 
		rm -fr $archive/
	fi
}

archive_list() {
	info "Archives:"

		local list=( $(_archive_list) )

		for file in "${list[@]}"
		do
			echo "   - $file"
		done
}

archive_listl() {
	info "Archives:"

	local list=( $(_archive_list) )

	for file in "${list[@]}"
	do
		if [[ -L $rr_archive_home/$file ]]
		then
			echo "   - $file -> $(readlink $rr_archive_home/$file)"
		else
			echo "   - $file" 
		fi
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

archive_home() {
	info "Archive home: $rr_archive_home"
}

archive_help() {
	info "** Archive Commands **"
	echo 

	methods=( list create )
	for method in "${methods[@]}" 
	do
		echo "rr archive $method [options]*"
	done

	methods=( show edit install delete )
	for method in "${methods[@]}" 
	do
		echo "rr archive $method [options]* [ARCHIVE]"
	done
}

(
	archives=( $( _archive_list) )
	for archive in "${archives[@]}"
	do
		if [[ -h $rr_archive_home/$archive ]]
		then
			target=$( readlink $rr_archive_home/$archive )
			if [[ ! -d $target ]] 
			then
				rm -fr $rr_archive_home/$archive
			fi 
		fi 
	done
) || fail "Unable to cleanup archives." 

# Actually perform an action on the archives.
#
#
archive_action() {
	args=($*)
	action="${args[0]}"
	unset args[0]

	case "$action" in
		list|listl|show|create|delete|edit|install|home)
			archive_$action "${args[@]}"
			;;
		*)
			archive_help
			exit 1
			;;
	esac
}
