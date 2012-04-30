all_users() {
	cat /etc/group | sed 's|^\([^:]\+\):.*$|\1|'
}


# Returns the standard location of a user's
# home directory.  It is assumed that the root 
# user's home is always at /root and all other 
# users' homes are located at /home/$user
#
user_get_home() {
	echo "~$1"
}
