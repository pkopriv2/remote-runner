#! /bin/bash



# Installs the specified package.
package() {	
	echo "Installing package [$1]"
	apt-get install --force-yes "$1" 2>&1 >/dev/null

	#local installed=$(aptitude search $1 | grep "^i\s*\<$1\>\s")
	#if [[ "$installed" == "" ]]
	#then
	#else
		#echo "Package [$1] is already installed."
	#fi
}
