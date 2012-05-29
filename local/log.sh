#! /bin/bash

info() {
	if ! tput setaf &> /dev/null
	then
		echo -e "$1"
	else
		echo -e "$(tput setaf 2)$1$(tput sgr0)"
	fi
}

error() {
	if ! tput setaf &> /dev/null
	then
		echo -e "$1 >&2"
	else
		echo -e "$(tput setaf 1)$1$(tput sgr0)"
	fi
}

log_debug() {
	echo -e "[LOCAL:$(caller 0)] [DEBUG]: $1"
}

# Logs a message out in a friendly green color if 
# a tty has been allocated.
#
log_info() {
	if ! tput setaf &> /dev/null
	then
		echo -e "[LOCAL:$(caller 0)] [INFO]: $1"
	else
		echo -e "$(tput setaf 2)[LOCAL:$(caller 0)] [INFO]$(tput sgr0): $1"
	fi
}

# Logs a message out in a unfriendly red color. 
# The use should clearly know that something
# has gone wrong.
#
log_error() {
	if ! tput setaf &> /dev/null
	then
		echo [LOCAL:$(caller 0)]: $1 >&2
	else
		echo -e "$(tput setaf 1)[LOCAL:$(caller 0)]$(tput sgr0): $1" >&2
	fi
}
