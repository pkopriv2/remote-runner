#! /bin/bash

require "lib/login.sh"
require "lib/user.sh"
require "lib/host.sh"
require "local/log.sh"
require "key.sh"

rr_host_home=${rr_host_home:-$rr_home/hosts}
dir_create_if_missing "$rr_host_home"

# Lists all the hosts that have been bootstrapped.
#
host_list() {
	info "Boostrapped hosts:"

	local list=($(_host_list))

	for file in "${list[@]}"
	do
		echo "   - $file"
	done
}

_host_list() {
	local list=($(builtin cd "$rr_host_home" ; find . -maxdepth 1 -mindepth 1 -name '*.sh' -print | sed 's|\.\/||' | sed 's|\.sh||' | sort ))

	for file in "${list[@]}"
	do
		echo "$file"
	done
}

# Given a regexp string, return all the hosts
# that match.
#
#
_host_match() {
	if [[ -z $1 ]]
	then
		log_error "Must supply a non-empty regexp"
		exit 1
	fi 

	local list=($(_host_list))

	for host in "${list[@]}"
	do
		if expr "$host" : ".*$1" &> /dev/null
		then
			echo $host	
		fi
	done
}

# Creates the default host file.
# 
# @param $1 The full host login of the machine
# @param $2 The key file to use when logging into this machine.
#
_file_bootstrap() {
	info "Creating host file [$1] using key [$2]"

	cat > $rr_host_home/$1.sh <<EOH
#! /bin/bash
key "$2"
EOH
}


# Copies a public key to the specified host.
#
# @param $1 The full host login of the machine.  This is assumed to have been 
#           normalized, ie of the form (user@host)
# @param $2 The name of the key to copy.  This is assumed to have been
#           normalized. (keys are assummed to be of the form: 
#           id_rsa.<name>.pub).  
_ssh_bootstrap() {
	info "Copying key [$2] to host [$1]"

	local user=$(login_get_user "$1" 2> /dev/null)
	if [[ -z $user ]]
	then
		log_error "Unable to determine user from login [$1]"
		exit 1
	fi

	local pub_key=$(key_get "$2" 2> /dev/null)
	if [[ -z $pub_key ]]
	then 
		log_error "Unable to determine value of public key [$2]"
		exit 1
	fi

	ssh $1 "bash -s" 2>&1 > /dev/null <<EOH
		user_home=\$(eval "echo ~$user")
		if [[ ! -d \$user_home/.ssh ]]
		then
			mkdir \$user_home/.ssh
		fi

		if [[ ! -f \$user_home/.ssh/authorized_keys ]]
		then
			touch \$user_home/.ssh/authorized_keys
		fi

		IFS=$'\n'
		if ! grep "$pub_key" \$user_home/.ssh/authorized_keys
		then
			echo $pub_key >> \$user_home/.ssh/authorized_keys
		fi 
EOH
}

# Copies a public key to the specified host.
#
# @param $1 The hostname/ip of the host to bootstrap
# @param $2 The public key to send to the host. [default="default"]
host_bootstrap() {
	if [[ $# -lt 1 ]]
	then
		log_error "Must provide a host to bootstrap"
		exit 1
	fi

	local login=$(login "$1")
	local key_name=${2:-"default"}

	if ! _ssh_bootstrap "$login" "$key_name"
	then
		log_error "Unable to copy ssh keys."
		exit 1
	fi

	if ! _file_bootstrap "$login" "$key_name" 
	then
		log_error "Unable to bootstrap local host file."
		exit 1
	fi
}

# Show the details of the host.
#
host_show() {
	if [[ $# != 1 ]]
	then
		log_error "Must provide a login"
		exit 1
	fi

	local login=$(login "$1")
	if [[ ! -f $rr_host_home/$login.sh ]] 
	then
		log_error "That host [$login] has not been bootstrapped"
		exit 1
	fi

	local host=$(login_get_host "$login")
	local ip=$(host_get_ip "$host")

	info "$login: $ip"
	cat $rr_host_home/$login.sh | grep '^[^#]' | sed 's|^\(.\)|   \1|'
}

host_edit() {
	if [[ $# != 1 ]]
	then
		log_error "Must provide a login"
		exit 1
	fi

	local login=$(login "$1")
	if [[ ! -f $rr_host_home/$login.sh ]] 
	then
		log_error "That host [$login] has not been bootstrapped"
		exit 1
	fi

	local host=$(login_get_host "$login")
	${EDITOR:-vim} $rr_host_home/$login.sh
}

host_help() {
	echo "** Host Commands **"
	echo 

	methods=( list )
	for method in "${methods[@]}" 
	do
		echo "rr host $method [options]"
	done


	methods=( bootstrap show edit )
	for method in "${methods[@]}" 
	do
		echo "rr host $method [HOST] [options]"
	done
}


host_action() {
	args=($*)
	action="${args[0]}"
	unset args[0]

	case "$action" in
		list|bootstrap|show|edit)
			host_$action "${args[@]}"
			;;
		*)
			host_help
			exit 1
			;;
	esac
}
