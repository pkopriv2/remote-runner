#! /bin/bash

require "common.sh"
require "key.sh"

rr_host_home=${rr_host_home:-$rr_home/hosts}
dir_create_if_missing "$rr_host_home"

# Lists all the clients that have been bootstrapped.
#
#
client_list() {
	log_info "Boostrapped clients:"

	local list=($(builtin cd "$rr_host_home" ; find . -maxdepth 1 -mindepth 1 -name '*.sh' -print | sed 's|\.\/||' | sed 's|\.sh||' | sort ))

	for file in "${list[@]}"
	do
		echo "   - $file"
	done
}

# Creates the default client file.
# 
# @param $1 The full client login of the machine
# @param $2 The key file to use when logging into this machine.
#
_file_bootstrap() {
	log_info "Creating host file [$1] using key [$2]"

	cat > $rr_host_home/$1.sh <<EOH
#! /bin/bash

key_name=$2 
EOH
}


# Copies a public key to the specified host.
#
# @param $1 The full client login of the machine.  This is assumed to have been 
#           normalized, ie of the form (user@host)
# @param $2 The name of the key to copy.  This is assumed to have been
#           normalized. (keys are assummed to be of the form: 
#           id_rsa.<name>.pub).  
_ssh_bootstrap() {
	log_info "Copying key [$2] to host [$1]"

	if ! local user_home=$(user_get_home "$(login_get_user "$1")" &> /dev/null) 
	then
		log_error "Unable to determine user home from login [$1]"
		exit 1
	fi

	if ! local pub_key=$(key_get "$2" &> /dev/null)
	then 
		log_error "Unable to determine value of public key [$2]"
		exit 1
	fi

	ssh $1 "bash -s" 2>&1 >/dev/null <<EOH
		if [[ ! -d $user_home/.ssh ]]
		then
			mkdir $user_home/.ssh
		fi

		IFS=$'\n'
		if [[ -f $user_home/.ssh/authorized_keys ]]
		then 
			if ! grep "$pub_key" $user_home/.ssh/authorized_keys
			then
				echo $pub_key >> $user_home/.ssh/authorized_keys
			fi 
		fi
EOH
}

# Copies a public key to the specified host.
#
# @param host The hostname/ip of the client to bootstrap
# @param key_file The public key to send to the client. [default="default"]
client_bootstrap() {
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

# Reads a command from std in
#
client_execute() {
	if [[ -z $1  ]]
	then
		log_error "Must provide a hostname."
		exit 1
	fi
	
	local login=$(login "$1")

	if ! source $rr_host_home/$login.sh
	then
		log_error "Client [$login] has not been bootstrapped"
		exit 1
	fi

	local key_file=$rr_key_home/id_rsa.$key_name

	if [[ $# == 1 ]]
	then
		ssh -i "$key_file" $login "bash -s" 
		exit $?
	fi

	if [[ ! -f $2 ]] 
	then
		log_error "Unable to locate file [$2]"
		exit 1
	fi

    {
cat $rr_host_home/$login.sh
cat $rr_home/common.sh
cat $rr_home/lib/lib.sh
cat $rr_home/lib/user.sh
cat $2
	} | ssh -t -i $key_file $login "bash -s"
}

# Show the details of the client.
#
client_show() {
	if [[ $# != 1 ]]
	then
		log_error "Must provide a login"
		exit 1
	fi

	local login=$(login "$1")
	if [[ ! -f $rr_host_home/$login.sh ]] 
	then
		log_error "That client [$login] has not been bootstrapped"
		exit 1
	fi

	local host=$(login_get_host "$login")
	local ip=$(host_get_ip "$host")

	log_info "$login: $ip"
	echo 
	cat $rr_host_home/$login.sh | grep '^[^#]'
}

client_action() {
	args=($*)
	action="${args[0]}"
	unset args[0]

	case "$action" in
		list|bootstrap|execute|show)
			client_$action "${args[@]}"
			;;
		*)
			key_help
			exit 1
			;;
	esac
}
