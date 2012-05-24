#! /bin/bash

require "fileserver.sh"

_require() {
	cat-<<EOH
require() {}
EOH

}

# Given an archive
#
# $1 - The archive to run
# $2 - The host to be run on
#
lib() {
	for script in $rr_home/lib/*.sh
	do
		cat $script
	done

	for script in $rr_home/dsl/*.sh
	do
		cat $script
	done

	for script in $rr_archive_home/$1/scripts/*.sh
	do
		cat $script
	done

	cat "$rr_host_home/$host.sh"
}
