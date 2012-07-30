#! /bin/bash

set -o errexit
set -o errtrace

require "lib/msg.sh"
require "lib/trap.sh"

# Processes an embedded bash file (*.esh) and if successful, prints
# the outputs to standard out.
# 
# $1 - The esh file.
#
ebash_process_file() {
	if [[ -z $1 ]] 
	then
		fail "Must provide a ebash file."
	fi 

	local file=$1
	if [[ ! -f $file ]] 
	then
		fail "Must provide a ebash file."
	fi 

	local tmp_file=/tmp/ebash.tmp
	if ! touch $tmp_file &> /dev/null
	then
		fail "Must provide a ebash file."
	fi 

	delim=${ebash_delim:-"--"}

	{
		while read line 
		do
			# is this the first line, and is it a bash cmd?
			if [[ -z $cmd ]] && ! echo $line | grep -q "^$delim"
			then
				cmd=false
				echo "cat - <<-EOF"
				echo $line
				continue
			fi

			# is this the start or end of a bash cmd area?
			if echo $line | grep -q "^$delim"
			then 
				if [[ -z $cmd ]] || ! $cmd
				then
					echo "EOF"
					cmd=true
					continue
				fi

				echo "cat - <<-EOF"
				cmd=false
				continue
			fi

			echo $line

		done < $file

		$cmd || echo "EOF" 

	} | cat - > $tmp_file

	ebash_on_exit() {
		rm -f $tmp_file
	}

	ebash_on_source_error() {
		local line_num=$1

		fail "Error sourcing stdin: $line_num"
	}

	ebash_on_template_error() {
		local line_num=$1

		# The line number of the /tmp/bashee.out file will be
		# offset by one from the real template since we 
		# added an extra line at the beginning.
		(( line_num-- )) 

		fail "Error procesing template: $file: $line_num"
	}

	trap_push "ebash_on_exit" EXIT INT
	trap_push "ebash_on_source_error" ERR


	if ! test -t 0
	then
		source /dev/stdin
	fi

	trap_pop ERR
	trap_push "ebash_on_template_error" ERR

	source $tmp_file

	trap_pop ERR
	
	rm -f $tmp_file
}
