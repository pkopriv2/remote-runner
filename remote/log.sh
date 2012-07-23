require "lib/array.sh"

log_level=${log_level:-INFO}
rr_pid=${rr_pid:-"-1"}


debug_levels=( DEBUG )
log_debug() {
	if ! array_contains "$log_level" "${debug_levels[@]}" 
	then
		return 0
	fi

	if ! tput setaf &> /dev/null
	then
		echo -e "[$HOSTNAME] [$rr_pid] [DEBUG]: $1"
	else
		echo -e "$(tput setaf 5)[$HOSTNAME] [$rr_pid] [DEBUG]$(tput sgr0): $1"
	fi
}

# Logs a message out in a friendly green color if 
# a tty has been allocated.
#
info_levels=( DEBUG INFO )
log_info() {
	if ! array_contains "$log_level" "${info_levels[@]}" 
	then
		return 0
	fi

	if ! tput setaf &> /dev/null
	then
		echo -e "[$HOSTNAME] [$rr_pid] [INFO]: $1"
	else
		echo -e "$(tput setaf 5)[$HOSTNAME] [$rr_pid] [INFO]$(tput sgr0): $1"
	fi
}

# Logs a message out in a unfriendly red color. 
# The use should clearly know that something
# has gone wrong.
#
error_levels=( DEBUG INFO ERROR )
log_error() {
	if ! array_contains "$log_level" "${error_levels[@]}" 
	then
		return 0
	fi

	if ! tput setaf &> /dev/null
	then
		echo [$HOSTNAME] [$rr_pid] [ERROR]: $1 >&2
	else
		echo -e "$(tput setaf 5)[$HOSTNAME] [$rr_pid] [ERROR]$(tput sgr0): $1" >&2
	fi
}
