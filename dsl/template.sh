#! /bin/bash

rr_home_remote=${rr_home_remote:-/tmp/rr}
rr_esh_delimiter=${rr_esh_delimiter:-"--"}

template() {
	if [[ -z $archive_name ]]
	then
		fail "Unknown archive."
	fi 

	if [[ -z $1 ]]
	then
		fail "Must supply a file name."
	fi 

	log_info "Processing template [$1]"

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

	local permissions="755"
	permissions() {
		permissions=$1
	}

	. /dev/stdin

	eval "path=$1"
	log_debug "Path has expanded to: $path"

	local template=$rr_home_remote/$archive_name/templates/$src
	log_debug  "Retrieving template from: $template"

	if [[ ! -f $template ]]
	then
		fail "Template [$src] does not exist in archive [$archive_name]"
	fi 


	# Process the template file, which is interpreted as an embedded bash
	# file.  
	(
		set -o errexit 

		local bash_cmd=false
		{
			while read line
			do
				if echo $line | grep -q "^$rr_esh_delimiter" 
				then
					if $bash_cmd 
					then
						source /tmp/template$src
						echo > /tmp/template$src

						bash_cmd=false
						continue
					else
						bash_cmd=true
						continue
					fi
				fi


				if $bash_cmd
				then 
					echo $line >> /tmp/template$src
				else
					echo $line
				fi
			done < $template 
		} | cat - > $path 

		rm -f /tmp/template$src
	) || fail "Error processing template"

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
