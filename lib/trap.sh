#! /bin/bash

require "lib/fail.sh"

declare -a traps

signals=( ERR EXIT INT )

for sig in "${signals[@]}"
do
	local src=$(
		cat - <<-EOH
			callbacks_$sig=()

			on_$sig() {
				let last_index=\${#callbacks_$sig[@]}-1 || true

				while (( \$last_index >= 0 ))
				do
					callback=\${callbacks_$sig[\$last_index]}
					\$callback "\${@}"	
					let last_index=\$last_index-1 || true 
				done
			}

			trap "on_$sig \\\$LINENO" $sig
		EOH
	)

	eval "$src"
done

trap_push() {
	local function_name=$1
	if [[ -z $function_name ]]
	then
		fail "Must provide a function name"
	fi 
	shift

	while (( $# > 0 )) 
	do
		local signal=$1
		if [[ -z $signal ]]
		then
			fail "Must provide a signal"
		fi 
		shift

		eval "callbacks_$signal+=( $function_name )"
	done
}

trap_pop() {
	local signal=$1
	if [[ -z $signal ]]
	then
		fail "Must provide a signal"
	fi 

	local src=$(
		cat - <<-EOH
			let last_index=\${#callbacks_$signal[@]}-1 
			unset callbacks_$signal[\$last_index]
		EOH
	)

	eval "$src"
}
