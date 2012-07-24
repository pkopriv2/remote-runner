#! /bin/bash

set -o errtrace
set +o noglob 

rr_tmp_local=${rr_tmp_local:-/tmp}
rr_tmp_remote=${rr_tmp_remote:-/tmp}
rr_cmd_sudo=false

require "local/log.sh"
require "lib/msg.sh"
require "lib/msg.sh"
require "lib/array.sh"

require "host.sh"
require "key.sh"
require "role.sh"
require "archive.sh"

if [[ -f $rr_tmp_local/rr.tar ]]
then
	rm -f $rr_tmp_local/rr.tar
fi

on_exit() {
	rm -f $rr_tmp_local/rr.tar
	rm -f $rr_tmp_local/run.sh
}

trap 'on_exit' EXIT INT


# Given a list of archives, this function generates the library to be run 
# on the remote host. The library will take the form:
#	* rr/
#	* rr/lib/*
#	* rr/dsl/*
#	* rr/remote/*
#	* rr/archives/*
#
_lib_create() {
	local archives=( "${@}" )

	log_info "Building archive library from archives: $(array_print ${archives[@]})"

	# add the standard library files.
	griswold -o $rr_tmp_local/rr.tar  \
			 -C $rr_home			  \
			 -b rr					  \
			 require.sh				  \
			 bin/bashee				  \
			 bin/griswold			  \
			 lib					  \
			 dsl					  \
			 remote

	# start building the "run" script
	{
		echo "set -o errtrace"
		echo "set -o allexport" 
		echo 

		cat -<<-EOH
			on_error() {
				echo "Exiting script." 1>&2
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
		echo "rr_home_remote=\$rr_home"
		echo "rr_pid=$$"
		echo 

		echo "PATH=\$rr_home/bin:\$PATH"

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
			fail "Unable to locate archive script [$archive_script]"
		fi

		if ! tar -tf $rr_tmp_local/rr.tar | grep -q "archives\/$archive_name"
		then
			log_debug "The archive [$archive_name] has not been added."

			griswold -o $rr_tmp_local/rr.tar  \
					 -c $rr_archive_home	  \
					 -b rr/archives			  \
					 $archive_name					
		fi

		{
			echo "archive_name=$archive_name"
			echo "source \$rr_home/archives/$archive_name/scripts/$archive_script.sh"
		} | cat ->> $rr_tmp_local/run.sh
	done

	griswold -o $rr_tmp_local/rr.tar  \
			 -c $rr_tmp_local		  \
			 -b rr					  \
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
			tar -pxf $rr_tmp_remote/rr_tmp.tar -C $rr_tmp_remote
			if $rr_cmd_sudo 
			then
				sudo bash $rr_tmp_remote/rr/run.sh
			else
				bash $rr_tmp_remote/rr/run.sh
			fi
		CMD
	)

	ssh -q -t -i $key_file $1 "$cmd"
}

run() {
	local host_regexps=()
	local tmp_roles=()
	local tmp_archives=()
	
	while [[ $# -gt 0 ]]
	do
		arg="$1"

		case "$arg" in
			-l|--log-level)
				shift
				log_level="$1"
				;;
			-r|--role)
				shift
				tmp_roles+=( "$1" )
				;;
			-a|--archives)
				shift
				tmp_archives+=( "$1" )
				;;
			-h|--host)
				shift
				host_regexps+=( "$1" )
				;;
			-s|--sudo)
				rr_cmd_sudo=true
				;;
			*)
				host_regexps+=( "$1" )
				;;
		esac
		shift
	done

	log_debug "Collecting hosts that match: $(array_print "${host_regexps[@]}")"

	if [[ ${#host_regexps[@]} -eq 0 ]]
	then
		error "Must provide at least one host regexp."
		exit 1
	fi

	local hosts=$( _host_matchall "${host_regexps[@]}" )
	log_info "Hosts have expanded to: $(array_print "${hosts[@]}")"

	for host in "${hosts[@]}"
	do
		(
		# Source the host file.  This will set the following
		# global variables:
		#	- key
		#	- roles
		#
		_source_host $host

		# if roles were provided as arguments then use those.
		if [[ ${#tmp_roles[@]} -gt 0 ]]
		then
			roles=$tmp_roles
		fi

		# Source the roles.  This will set the following
		# global variables:
		#	- attributes
		#	- archives
		#
		_source_roles ${roles[@]}

		# if archives were provided as arguments then use those.
		if [[ ${#tmp_archives[@]} -gt 0 ]]
		then
			archives=$tmp_archives
		fi

		# Determine the necessary ssh key to use to 
		# run on this host.  Add the identity file
		# to limit the number of times that the passphrase
		# is requested. This will set the following 
		# global variables:
		#	- key_file
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

		# create the library
		_lib_create "${archives[@]}"

		# finally run the library on the remote host.
		_lib_run $host $key_file

		) || fail "Error executing host [$host] runlist."
	done
}


run_help() {
	local detailed=false
	while [[ $# -gt 0 ]]
	do
		arg="$1"

		case "$arg" in
			-d|--detailed)
				detailed=true
				;;
		esac
		shift
	done

	echo "rr run [options] host1 .. hostn"

	if ! $detailed 
	then
		return 0
	fi

	printf "%s\n" "
OPTIONS:
  -h|--host    The hosts on which to run. 
  -r|--role    The roles to source.  Multiple may be provived. This 
			   overrides any roles in the host files.

  -a|--archive The archive to run.	Multiple may be provided.  This 
			   overrides any archives in the role files.

  -s|--sudo    Execute the runlist as the sudo root user.  If the sudo 
			   user requires a password, this cannot be daemonized.
"
	echo 
}

run_action() {
	args=( "${@}" )
	action="${args[0]}"

	case "$action" in
		help)
			run_help --detailed
			;;
		*)
			run "${args[@]}"
			;;
	esac
}
