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


# Accepts an auth string and 
#
uri() {
	if [[ "$(expr "$1" : "^[^ ]\+@[^ ]\+$")" != "0" ]]
	then 
		echo "$1"
		exit 0
	fi 

	echo "root@$1"
}

# Gets the host portion of a login uri.
# Login uris follow the pattern: user@host
#
uri_get_host() {
	expr "$1" : "@\([^ ]\+\)$"
}


# Gets the user portion of a login uri.
# Login uris follow the pattern: user@host
#
uri_get_user() {
	expr "$1" : "^\([^ ]\+\)@"
}

# Returns the standard location of a user's
# home directory.  It is assumed that the root 
# user's home is always at /root and all other 
# users' homes are located at /home/$user
#
user_get_home() {
	if [[ "$1" == "root" ]]
	then
		echo "/root"
	else
		echo "/home/$1"
	fi
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
	echo -e "$(tput setaf 1)$1$(tput sgr0)" >&2
}
