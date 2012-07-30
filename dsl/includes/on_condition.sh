#! /bin/bash

on_condition_reset() {
	on_condition_func() {
		return 0
	}
}

on_condition_reset

on_condition() {
	if [[ -z $1 ]]
	then
		on_condition_src=$(cat -)
	else
		on_condition_src="$1"
	fi

	local src=$(
		cat - <<-SRCHDMARKER
			on_condition_func() {
				$on_condition_src
			}
		SRCHDMARKER
	)

	eval "$src" 
}
