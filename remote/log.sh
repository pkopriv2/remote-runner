log_level=${log_level:-DEBUG}

debug_levels=( DEBUG )
log_debug() {
	if ! array_contains "$log_level" "${debug_levels[@]}" 
	then
		return 0
	fi

	echo -e "[REMOTE:$(caller 0)] [DEBUG]: $*" 
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

	echo -e "[REMOTE:$(caller 0)] [INFO]: $1"
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

	echo -e "[REMOTE:$(caller 0)] [ERROR]: $*" 1>&2
}
