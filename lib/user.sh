# user.sh
# 
# Provides common utility functions for getting information
# about and manipulating system users.
#

# Returns all the users on a given system.
#
all_users() {
	cat /etc/group | sed 's|^\([^:]\+\):.*$|\1|'
}


# Returns the standard location of a user's
# home directory.  No assumptions are made
# about the user's home directory.
#
# @param $1 The username.
#
user_get_home() {
	eval "echo ~$1"
}

# Returns the primary group of the 
# given user
#
# @param $1 the username
user_get_primary_group() {
	id -g -n $1
}
