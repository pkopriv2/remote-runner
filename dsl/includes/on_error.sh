#! /bin/bash

# 
on_error_reset() {
	on_error_func() {
		return 0
	}

	trap_pop ERR
}

# define the callback method
on_error() {
	if [[ -z $1 ]]
	then
		on_error_src=$(cat -)
	else
		on_error_src="$1"
	fi

	local src=$(
		cat - <<-SRCHDMARKER
			on_error_func() {
				$on_error_src
			}

			trap_push on_error_func ERR
		SRCHDMARKER
	)

	eval "$src" 
}
