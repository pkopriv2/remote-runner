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
login() {
	if [[ "$(expr "$1" : "^[^ ]\+@[^ ]\+$")" != "0" ]]
	then 
		echo "$1"
		exit 0
	fi 

	echo "root@$1"
}

# Gets the host portion of a login login.
# Login logins follow the pattern: user@host
#
login_get_host() {
	expr "$1" : "^[^ ]\+@\([^ ]\+\)$"
}


# Gets the user portion of a login login.
# Login logins follow the pattern: user@host
#
login_get_user() {
	expr "$1" : "^\([^ ]\+\)@"
}

# Gets the ip of the host.  Expecting the output of
# the host command to be:
#  	pkopriv2-fileserver has address 192.168.100.3
# 
host_get_ip() {
	expr "$(host $1)" : "^$1 has address \(.*\)$"
}

user_get_home() {
	echo ~$1
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
