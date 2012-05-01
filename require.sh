#! /bin/bash

rr_home=${rr_home:-$HOME/.rr}

declare -A requires

require() {
	local script=$rr_home/$1
	if [[ ! -f "$script" ]]
	then
		echo "Unable to locate script: $script"
		exit 1
	fi

	if [[ "${requires["$script"]}" == "1" ]]
	then
		return
	fi
	
	. $script  && requires["$script"]="1"
}
