#! /bin/bash


# Installs the specified package.
package() {	
	log_info "Installing package [$1]"
	echo "Y" | apt-get install "$1"
}
