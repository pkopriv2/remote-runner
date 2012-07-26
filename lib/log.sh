require "lib/array.sh"

rr_log_level=${rr_log_level:-"INFO"}
rr_log_local=${rr_log_local:=true}
rr_log_color=${rr_log_color:=true}
rr_log_pid=${rr_log_pid:-$$}

# determine what log color and tag to use.
if [[ "$rr_log_local" == "true" ]]
then
	if [[ "$rr_log_color" == "true" ]]
	then
		rr_log_color_id=${log_rr_log_color_id:-2}
	fi

	rr_log_host=LOCAL
else
	if [[ "$rr_log_color" == "true" ]]
	then
		rr_log_color_id=${log_rr_log_color_id:-5}
	fi

	rr_log_host=$HOSTNAME
fi

debug_levels=( DEBUG )
log_debug() {
	if ! array_contains "$rr_log_level" "${debug_levels[@]}" 
	then
		return 0
	fi

	if [[ "$rr_log_color" != "true" ]] || ! tput setaf &> /dev/null 
	then
		echo -e "[$rr_log_host] [$rr_log_pid] [DEBUG]: $1"
	else
		echo -e "$(tput setaf $rr_log_color_id)[$rr_log_host] [$rr_log_pid] [DEBUG]$(tput sgr0): $1"
	fi
}

# Logs a message out in a friendly green rr_log_color if 
# a tty has been allocated.
#
info_levels=( DEBUG INFO )
log_info() {
	if ! array_contains "$rr_log_level" "${info_levels[@]}" 
	then
		return 0
	fi

	if [[ "$rr_log_color" != "true" ]] || ! tput setaf &> /dev/null 
	then
		echo -e "[$rr_log_host] [$rr_log_pid] [INFO]: $1"
	else
		echo -e "$(tput setaf $rr_log_color_id)[$rr_log_host] [$rr_log_pid] [INFO]$(tput sgr0): $1"
	fi
}

# Logs a message out in a unfriendly red rr_log_color. 
# The use should clearly know that something
# has gone wrong.
#
error_levels=( DEBUG INFO ERROR )
log_error() {
	if ! array_contains "$rr_log_level" "${error_levels[@]}" 
	then
		return 0
	fi

	if [[ "$rr_log_color" != "true" ]] || ! tput setaf &> /dev/null 
	then
		echo "[$rr_log_host] [$rr_log_pid] [ERROR]: $1" 1>&2
	else
		echo -e "$(tput setaf $rr_log_color_id)[$rr_log_host] [$rr_log_pid] [ERROR] $(tput sgr0): $1" 1>&2
	fi
}
