#! /bin/bash

on_change_reset() {
	on_change_func() {
		return 0
	}
}

on_change_reset

on_change() {
	if [[ -z $1 ]]
	then
		on_change_src=$(cat -)
	else
		on_change_src="$1"
	fi

	local src=$(
		cat - <<-SRCHDMARKER
			on_change_func() {
				$on_change_src

				unset on_change_func
			}
		SRCHDMARKER
	)

	eval "$src" 
}
