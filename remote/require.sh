#! /bin/bash

rr_tmp_remote=${rr_tmp_remote:-/tmp/rr}

declare -A requires

require() {
	local script=$rr_tmp_remote/$1
	if [[ ! -f "$script" ]]
	then
		echo "Unable to locate script: $script"
		exit 1
	fi

	if [[ "${requires["$script"]}" == "1" ]]
	then
		return
	fi
	
	source $script && requires["$script"]="1"
}
