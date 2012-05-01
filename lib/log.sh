#! /bin/bash

# Logs a message out in a friendly green color if 
# a tty has been allocated.
#
log_info() {
	if ! tput &> /dev/null
	then
		echo $1
	else
		echo -e "$(tput setaf 2)$1$(tput sgr0)"
	fi
}

# Logs a message out in a unfriendly red color. 
# The use should clearly know that something
# has gone wrong.
#
log_error() {
	if ! tput &> /dev/null
	then
		echo $1 >&2
	else
		echo -e "$(tput setaf 1)$1$(tput sgr0)" >&2
	fi
}
