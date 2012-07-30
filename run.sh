#! /bin/bash

set -o errtrace
set +o noglob 

rr_tmp_local=${rr_tmp_local:-/tmp}
rr_tmp_remote=${rr_tmp_remote:-/tmp}
rr_cmd_opts=()

require "lib/log.sh"
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

if [[ -d $rr_tmp_local/rr ]]
then
	rm -rf $rr_tmp_local/rr
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
			 bin/griswold			  \
			 lib					  \
			 dsl					  

	# start building the "run" script
	{
		# bash options
		cat -<<-EOH
			set -o errtrace
			set -o errexit
			set -o allexport

			PATH=\$rr_home/bin:\$PATH
		EOH

		# user defined attributes
		for key in "${!attributes[@]}"
		do
			echo "$key=${attributes[$key]}"
		done

		# program defined attributes
		cat -<<-EOH
			rr_home=$rr_tmp_remote/rr
			rr_home_remote=\$rr_home
			rr_log_level=${rr_log_level:-"INFO"}
			rr_log_color=${rr_log_color:-"true"}
			rr_log_local=false
			rr_log_pid=$rr_log_pid

			source \$rr_home/require.sh
		EOH

		# simple error handlers 
		cat -<<-EOH
			require "lib/trap.sh"

			on_error() {
				echo "Exiting script." 1>&2
				caller 0 1>&2					
			}

			trap_push 'on_error' ERR

		EOH

		# import all the necessary scripts 
		for script in $rr_home/lib/*.sh
		do
			echo "require \"lib/$(basename $script)\""
		done

		for script in $rr_home/dsl/*.sh
		do
			echo "require \"dsl/$(basename $script)\""
		done

		echo
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
			on_tmp_exit() {
				rm -fr $rr_tmp_remote/rr
				rm -f  $rr_tmp_remote/rr_tmp.tar
			}
			
			trap 'on_tmp_exit' INT EXIT

			tar -pxf $rr_tmp_remote/rr_tmp.tar -C $rr_tmp_remote

			bash $rr_tmp_remote/rr/run.sh
		CMD
	)

	ssh -q -t -i $key_file $host "${rr_cmd_opts[*]} bash -l -c \"$cmd\""
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
				rr_log_level="$1"
				;;
			--no-color)
				rr_log_color=false
				;;
			-s|--sudo)
				rr_cmd_opts+=( "sudo" )
				;;
			-r|--role)
				shift
				tmp_roles+=( "$1" )
				;;
			-a|--archive)
				shift
				tmp_archives+=( "$1" )
				;;
			-h|--host)
				shift
				host_regexps+=( "$1" )
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

	local hosts=( $( _host_matchall "${host_regexps[@]}" ) )
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
  -h|--host       The hosts on which to run. 
  -r|--role       The roles to source.  Multiple may be provived. This 
                  overrides any roles in the host files.

  -a|--archive    The archive to run.  Multiple may be provided.  This 
                  overrides any archives in the role files.

  -s|--sudo       Execute the runlist as the sudo root user.  If the sudo 
                  user requires a password, this cannot be daemonized.
  -l|--log-level  Set the local log level.  Can be one of: DEBUG INFO ERROR
  --no-color      Suppress color output.

"
}

run_action() {
	args=( "${@}" )
	action="${args[0]}"

	case "$action" in
		help|--help|-h)
			run_help --detailed
			;;
		*)
			run "${args[@]}"
			;;
	esac
}
