require "lib/fail.sh"

# See if the input inode is owned by the given owner.
#
# $1 - The inode (can be a directory)
# $2 - The owner
#
inode_has_owner?() {
	if (( $# < 2 ))
	then
		fail "Must provide a inode and an owner"
	fi

	if [[ ! -f $1 ]] && [[ ! -d $1 ]] 
	then
		fail "That inode [$1] does not exist."
	fi

	[[ $(stat --format '%U' $1) == $2 ]]; return $?
}

# See if the input inode is owned by the given group.  
#
# $1 - The inode (can be a directory)
# $2 - The group
#
inode_has_group?() {
	if (( $# < 2 ))
	then
		fail "Must provide a inode and an group"
	fi

	if [[ ! -f $1 ]] && [[ ! -d $1 ]] 
	then
		fail "That inode [$1] does not exist."
	fi

	[[ $(stat --format '%G' $1) == $2 ]]; return $?
}

# See if the input inode has the given permissions 
#
# $1 - The inode (can be a directory)
# $2 - The group
#
inode_has_permissions?() {
	if (( $# < 2 ))
	then
		fail "Must provide a inode and an group"
	fi

	if [[ ! -f $1 ]] && [[ ! -d $1 ]] 
	then
		fail "That inode [$1] does not exist."
	fi

	[[ $(stat --format '%a' $1) == $2 ]]; return $?
}
