#! /bin/bash

set -o errtrace
set +o noglob 

require "lib/log.sh"
require "lib/fail.sh"
require "lib/dir.sh"
require "lib/msg.sh"
require "lib/array.sh"
require "lib/string.sh"
require "lib/login.sh"

require "host.sh"
require "key.sh"

rr_tmp_local=${rr_tmp_local:-/tmp}
rr_tmp_remote=${rr_tmp_remote:-/tmp}
rr_remote_file=${rr_remote_file:-$rr_tmp_remote/rr_remote_cmd.tmp}
rr_cmd_local=${rr_cmd_loca:-$rr_tmp_local/rr_cmd}
rr_cmd_opts=()
rr_source=true

on_exit() {
	rm -f $rr_cmd_local
}

trap 'on_exit' EXIT INT

cmd_help() {
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

	echo "rr cmd [options] [cmd]"

	if ! $detailed 
	then
		return 0
	fi

	printf "%s\n" "
OPTIONS:
  -h|--host      The hosts to run the command against.  Multiple are allowed.
  -f|--file      The file to run on each host.
  -c|--cmd       The command to run on each host.
  -s|--sudo      Run the command/script as the sudo root user.
  -e|--editor    Open an editor to get the command.
  -l|--log-level Set the local log level.  Can be one of: DEBUG INFO ERROR
  --no-color     Suppress color output.
"
}

_script_run() {
	local login=$1
	local script=$2
	local key_file=$3

	log_info "Executing command on host [$host]"

	local cmd=$( 
		cat - <<-OUTERCMD
			on_tmp_exit() {
				rm $rr_remote_file
			}

			trap 'on_tmp_exit' INT EXIT

			cat - > $rr_remote_file <<-EOH
				$(cat $script)
			EOH

			chmod +x $rr_remote_file 

			$rr_remote_file
		OUTERCMD
	)

	ssh -q -t -i $key_file $login "${rr_cmd_opts[*]} bash -l -c \"$cmd\""
}

cmd() {
	local host_regexps=()

	declare script
	declare cmd
	
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
			-c|--cmd)
				shift
				cmd=$1
				;;
			-f|--file)
				shift
				script=$1
				;;
			-s|--sudo)
				rr_cmd_opts+=( sudo )
				;;
			-h|--host)
				shift
				host_regexps+=( "$1" )
				;;
			-e|--editor)
				${EDITOR:-vim} $rr_cmd_local
				script=$rr_cmd_local
				;;
			*)
				cmd=$1
				;;
		esac
		shift
	done

	if [[ -z $cmd ]] && [[ -z $script ]] 
	then 
		error "Must provide either a command string or a file." 
		exit 1
	fi

	if [[ ! -z $cmd ]] 
	then
		# the command can either be a file or a bash command.
		if [[ -f $cmd ]]
		then
			script=$cmd
		else
			script=$rr_cmd_local
			echo "$cmd" > $script
		fi
	fi

	if [[ ! -f $script ]]
	then
		error "No file to execute!"
		exit 1
	fi

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
		# 	- key
		_source_host $host

		# Source the key file.  This will set the following 
		# global variables:
		# 	- key_file
		_source_key $key

		# execute the script
		_script_run $host $script $key_file

		) || fail "Error executing cmd on host [$host]."
	done
}

cmd_action() {
	args=( "${@}" )
	action="${args[0]}"

	case "$action" in
		help|--help|-h)
			cmd_help --detailed
			;;
		*)
			cmd "${args[@]}"
			;;
	esac
}
