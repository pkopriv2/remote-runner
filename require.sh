#! /bin/bash

rr_home=${rr_home:-$HOME/.rr}

declare -A requires

require() {
	local script=$rr_home/$1
	if [[ ! -f "$script" ]]
	then
		echo "Unable to locate script: $script" 1>&2 
		caller 0 1>&2
		exit 1
	fi

	if [[ "${requires["$script"]}" == "1" ]]
	then
		return
	fi
	
	source $script && requires["$script"]="1"
}
