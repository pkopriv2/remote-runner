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

	if ! local uri=$(uri "$1")
	then
		exit 1
	fi

	if ! local user_home=$(user_get_home "$(uri_get_user "$uri")")
	then
		exit 1
	fi

	if ! local pub_key=$(key_get "${2:-default}")
	then 
		 exit 1
	fi

	local err=$(
	ssh $uri "bash -s" 2>&1 >/dev/null <<EOH

		if [[ ! -d $user_home/.ssh ]]
		then
			mkdir $user_home/.ssh
		fi

		IFS=$'\n'
		if [[ -f $user_home/.ssh/authorized_keys ]]
		then 
			if grep "$pub_key" $user_home/.ssh/authorized_keys
			then
				echo "Key already exists" >&2
				exit 1
			fi 
		fi

		echo $pub_key >> $user_home/.ssh/authorized_keys
EOH
)
	if [[ "$err" ]]
	then
		log_error "Error bootstrapping client [$uri]: $err"
		exit 1
	fi

	cat > $rr_host_home/$uri.sh <<EOH
#! /bin/bash

key_name=${2:-default}
EOH
}

# Reads a command from std in
#
client_execute() {
	if [[ -z $1  ]]
	then
		log_error "Must provide a hostname."
		exit 1
	fi

	local host_file=$rr_host_home/$1.sh
	if [[ ! -f $host_file  ]]
	then
		log_error "Client [$1] has not been bootstrapped"
		exit 1
	fi

	source $host_file
	local key_file=$rr_key_home/id_rsa.$key_name

	{
		cat $host_file
		cat $2
	} | ssh -i $key_file root@$1 "bash -s"
}

client_action() {
	args=($*)
	action="${args[0]}"
	unset args[0]

	case "$action" in
		list|bootstrap|execute)
			client_$action "${args[@]}"
			;;
		*)
			key_help
			exit 1
			;;
	esac
}
