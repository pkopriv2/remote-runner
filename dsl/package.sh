#! /bin/bash


# Installs the specified package.
package() {	
	log_info "Processing package [$1]"

	local action="install"
	action() {
		action=$1
	}

	. /dev/stdin

	unset -f action
	package_"$action" $1
}
