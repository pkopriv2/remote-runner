#! /bin/bash


# Installs the specified package.
package() {	
	log_info "Installing package [$1]"
	apt-get install --force-yes "$1" 2>&1 >/dev/null
}
