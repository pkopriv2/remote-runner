require "lib/fail.sh"

if command -v dpkg &>/dev/null
then
	package_require() {
		if ! package_installed $1
		then
			package_install $1 || \
				fail "Package [$1] is required but is not installed"
		fi
	}

	package_installed() {
		echo $(dpkg -s $1) | grep "Status: install ok" > /dev/null && return $?
	}

	package_install() {
		package_installed $1 && return 0
		
		if ! command -v apt-get &> /dev/null
		then
			fail "apt-get is required to install packages."
		fi 

		echo "Y" | apt-get install $1
	}

	package_remove() {
		package_installed $1 || return 0

		if ! command -v apt-get &> /dev/null
		then
			fail "apt-get is required to remove packages."
		fi 

		echo "Y" | apt-get remove $1 
	}
else
	log_info "Your os package manager is not supported.  Calls to package_x will fail."
fi
