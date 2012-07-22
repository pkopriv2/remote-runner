#! /bin/bash

set -o errtrace
set +o noglob 

declare -A attributes

rr_tmp_local=${rr_tmp_local:-/tmp}
rr_tmp_remote=${rr_tmp_remote:-/tmp}


require "local/log.sh"
require "lib/msg.sh"
require "lib/array.sh"

require "host.sh"
require "key.sh"
require "role.sh"
require "archive.sh"

on_exit() {
	rm -f $rr_tmp_local/rr.tar
	rm -f $rr_tmp_local/run.sh
}

trap 'on_exit' EXIT INT


# Given a list of archives, this function generates the library to be run 
# on the remote host. The library will take the form:
#  	* rr/
#   * rr/lib/*
#   * rr/dsl/*
#   * rr/remote/*
#   * rr/archives/*
#
_lib_create() {
	local archives=( ${@} )

	log_info "Building archive library from archives: $(array_print ${archives[@]})"

	# add the standard library files.
	griswold -o $rr_tmp_local/rr.tar  \
			 -C $rr_home 			  \
		     -b rr  				  \
			 require.sh 		      \
			 lib 					  \
			 dsl 					  \
			 remote 					  

	# start building the "run" script
	{
		echo "set -o errtrace"
		echo "set -o allexport"
		echo 

		cat -<<-EOH
			on_error() {
				echo "An error occurred." 1>&2
				caller 0					
				exit 1
			}

			trap 'on_error' ERR

			on_exit() {
				rm -fr $rr_tmp_remote/rr
				rm -f  $rr_tmp_remote/rr_tmp.tar
			}

			trap 'on_exit' EXIT INT
		EOH

		echo 
		echo "rr_home=$rr_tmp_remote/rr"
		echo 

		echo "source \$rr_home/require.sh"
		echo 

		for script in $rr_home/lib/*.sh
		do
			echo "require \"lib/$(basename $script)\""
		done

		for script in $rr_home/dsl/*.sh
		do
			echo "require \"dsl/$(basename $script)\""
		done

		for script in $rr_home/remote/*.sh
		do
			echo "require \"remote/$(basename $script)\""
		done

		echo

		for key in "${!attributes[@]}"
		do
			echo "$key=${attributes[$key]}"
		done

		echo "log_level=$log_level"

		echo
	} | cat - > $rr_tmp_local/run.sh

	# add each archive to the library (and add their invocations to the run script)
	for archive in "${archives[@]}"
	do
		log_debug "Building archive library [$archive]"

		local archive_name=$(_archive_get_name $archive)
		if [[ ! -d $rr_archive_home/$archive_name ]]
		then
			fail "Unable to locate archive [$archive_name]"
		fi

		local archive_script=$(_archive_get_script $archive)
		if [ ! -f $rr_archive_home/$archive_name/scripts/$archive_script.sh ]
		then
			fail "Unable to locate archive [$archive]"
		fi

		if ! tar -tf $rr_tmp_local/rr.tar | grep -q "$archive_name"
		then
			log_debug "The archive [$archive_name] has not been added."

			griswold -o $rr_tmp_local/rr.tar  \
					 -c $rr_archive_home 	  \
					 -b rr/archives 		  \
					 $archive_name 					
		fi

		{
			echo "source \$rr_home/archives/$archive_name/scripts/$archive_script.sh"
		} | cat ->> $rr_tmp_local/run.sh
	done

	griswold -o $rr_tmp_local/rr.tar  \
			 -c $rr_tmp_local 	      \
			 -b rr 					  \
			 run.sh

	rm -f $rr_tmp_local/run.sh
}

_lib_run() {
	local host=$1
	local key_file=$2

	log_info "Executing runlist on host [$host]"

	scp -i $key_file $rr_tmp_local/rr.tar $host:$rr_tmp_remote/rr_tmp.tar &> /dev/null ||
		fail "Error transferring library to host [$host]"

	local cmd=$( 
		cat - <<-CMD
			tar -xf $rr_tmp_remote/rr_tmp.tar -C $rr_tmp_remote
			if $sudo 
			then
				sudo bash $rr_tmp_remote/rr/run.sh
			else
				bash $rr_tmp_remote/rr/run.sh
			fi
		CMD
	)

	ssh -t -i $key_file $1 "$cmd"
}

run() {
	host_regexps=()

	tmp_roles=()
	
	sudo=false
	while [[ $# -gt 0 ]]
	do
		arg="$1"

		case "$arg" in
			-l|--log_level)
				shift
				log_level="$1"
				;;
			-r|--role)
				shift
				tmp_roles+=( "$1" )
				;;
			-s|--sudo)
				sudo=true
				;;
			*)
				host_regexps+=( "$1" )
				;;
		esac
		shift
	done

	log_debug "Collecting hosts that match: $(array_print "${host_regexps[@]}")"

	local hosts=()
	for host_regexp in "${host_regexps[@]}"
	do
		hosts+=( $( _host_match $host_regexp) )
	done

	hosts=( $(array_uniq ${hosts[@]}) )

	log_info "Hosts have expanded to: $(array_print "${hosts[@]}")"

	for host in "${hosts[@]}"
	do
		(
		# Source the host file.  This will set the following
		# global variables:
		# 	- key
		#   - roles
		#
		_source_host $host

		# if roles were provided as arguments then use those.
		if [[ ${#tmp_roles[@]} -gt 0 ]]
		then
			roles=$tmp_roles
		fi

		# Source the roles.  This will set the following
		# global variables:
		#   - attributes
		#   - archives
		#
		_source_roles ${roles[@]}

		# Determine the necessary ssh key to use to 
		# run on this host.  Add the identity file
		# to limit the number of times that the passphrase
		# is requested. This will set the following 
		# global variables:
		# 	- key_file
		#
		_source_key $key

		log_info "Runlist has expanded to: $(array_print ${archives[@]}) "

		# Check to see if any archives have been applied to
		# this host.  If not, then we don't need to continue
		if [[ ${#archives} == 0 ]] 
		then
			log_info "No archives to execute."
			exit 0
		fi

		_lib_create "${archives[@]}"
		_lib_run $host $key_file

		) || fail "Error executing host [$host] runlist."
	done
}


run_help() {
	info "Usage: rr run [options] regexp [regexp]*"
	echo 

}

run_action() {
	args=($*)
	action="${args[0]}"

	case "$action" in
		help)
			run_help 
			;;
		*)
			run "${args[@]}"
			;;
	esac
}
