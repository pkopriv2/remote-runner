#! /bin/bash

# Installs the specified package.
package() {	
	echo "Installing package [$1]"

	local installed=$(aptitude search $1 | grep "^i\s*\<$1\>\s")
	if [[ "$installed" == "" ]]
	then
		apt-get install --force-yes "$1" 2>&1 >/dev/null
	else
		echo "Package [$1] is already installed."
	fi
}

file() {
	echo "Creating file [$1]"

	local innards=""
	contents() {
		innards=$(cat)
	}

	. /dev/stdin

	if ! touch $1 1> /dev/null
	then
		echo "Error creating file [$1]" >&2
		exit 1
	fi

	if ! chown ${owner:-"root"}:${group:-"root"} $1 
	then
		echo "Error setting ownership of file [$1]" >&2
		exit 1
	fi

	if ! chmod ${permissions:-"644"} $1
	then
		echo "Error setting permissions of file [$1]" >&2
		exit 1
	fi

	echo "$innards" | cat > $1
}
