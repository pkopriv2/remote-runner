#! /bin/bash

info() {
	if ! tput setaf &> /dev/null
	then
		echo -e "$1"
	else
		echo -e "$(tput setaf 2)$1$(tput sgr0)"
	fi
}

error() {
	if ! tput setaf &> /dev/null
	then
		echo -e "$1" 1>&2
	else
		echo -e "$(tput setaf 1)$1$(tput sgr0)" 1>&2
	fi
}

if (( $# > 0 )) 
then
	info "Installing version: $1"
	version=$1
else
	info "Installing latest version of remote-runner."
	version="latest" 
fi

if (( $UID == 0 )) 
then
	error "Installing as root is not currently supported."
	exit 1
else
	info "Installing as $USER."
	rr_home=${rr_home:-"~/.rr"}
	rr_install_dir=${rr_install_dir:-"~"}
	rr_profile=~/.profile
fi

rr_file_tmp=${rr_file_tmp:-"/tmp/rr.tar"}
rr_file_remote=${rr_file_remote:-"http://github.com/pkopriv2/download/remote-runner-$version.tar.gz"}

if ! wget --progress=bar -O $rr_file_tmp $rr_file_remote
then
	error "Error downloading remote runner [$rr_file_remote].  Either cannot download or cannot write to file [$rr_tmp_file]"
	exit 1
fi

if ! tar -xf $rr_tmp_file -C $rr_install_dir
then
	error "Error unpackaging tmp file [$rr_tmp_file]"
	exit 1
fi

if ! grep -q "rr_home=$rr_home" $rr_profile
then
	cat - >> $rr_profile <<-EOF

# Generated by: remote-runner
export rr_home=$rr_home
source $rr_home/env.sh
	EOF

	if (( $? )) 
	then 
		error "Error updating profile [$rr_home]"
		exit 1
	fi
fi

info "Successfully installed remote-runner!  Please resource your environment for changes to take effect."
