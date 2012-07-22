#! /bin/bash

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

# Returns a random string of the given length.
str_random() {
	tr -dc "[:alpha:]" < /dev/urandom | head -c ${1:-8}
}
