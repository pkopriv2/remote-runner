if command -v dpkg &>/dev/null
then
	package_require() {
		if ! _package_installed $1
		then
			error "Packaged [$1] is required but is not installed"
			exit 1
		fi
	}

	package_installed() {
		echo $(dpkg -s $1) | grep "Status: install ok" > /dev/null && return $?
	}

	#_package_install() {
		#_package_installed && return 0
	
	#}
else
	
	echo > /dev/null
fi
