require "lib/array.sh"

log_level=${log_level:-INFO}


debug_levels=( DEBUG )
log_debug() {
	if ! array_contains "$log_level" "${debug_levels[@]}" 
	then
		return 0
	fi

	echo -e "$(tput setaf 2)[LOCAL] [DEBUG]$(tput sgr0): $1"
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
		echo -e "[LOCAL] [INFO]: $1"
	else
		echo -e "$(tput setaf 2)[LOCAL] [INFO]$(tput sgr0): $1"
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
		echo [LOCAL]: $1 >&2
	else
		echo -e "$(tput setaf 1)[LOCAL]$(tput sgr0): $1" >&2
	fi
}
