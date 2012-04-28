#! /bin/bash

# Creates the directory if it doesn't already exist.
#
dir_create_if_missing() {
	if [[ ! -d "$1" ]] 
	then 
		mkdir "$1"
	fi
}

# Echoes a non-blank string, if the provided 
# string only contains whitespace. 
#
str_is_blank() {
	echo "$1" | grep '^\s*$' 
}

# Echoes the input str_is_blanking with leading 
# and ending whitespace removed
#
str_strip_whitespace() {
	echo $(echo "$1" | sed 's/^\s*//') | sed 's/\s*$//'
}

# Logs a message out in a friendly green color. 
#
log_info() {
	echo -e "$(tput setaf 2)$1$(tput sgr0)"
}

# Logs a message out in a unfriendly red color. 
# The use should clearly know that something
# has gone wrong.
#
log_error() {
	echo -e "$(tput setaf 1)$1$(tput sgr0)"
}
