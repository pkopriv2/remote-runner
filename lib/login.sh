# Accepts a login string and normalizes it to the
# form user@host.  If no user is supplied, then 
# root is assumed.
#
# @param login The login string.
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
# @param login The normalized login string. 
#
login_get_host() {
	expr "$1" : "^[^ ]\+@\([^ ]\+\)$"
}


# Gets the user portion of a login login.
# Login logins follow the pattern: user@host
#
# @param login The normalized login string. 
#
login_get_user() {
	expr "$1" : "^\([^ ]\+\)@"
}
