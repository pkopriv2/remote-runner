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

	cmd=$(
		cat - <<-EOH
			rr_home=~/.rr
			rr_bashrc=~/.bashrc
		EOH
	)

	eval "$cmd"
fi

rr_file_tmp=${rr_file_tmp:-/tmp/remote-runner.tar}
rr_file_remote=${rr_file_remote:-"https://github.com/downloads/pkopriv2/remote-runner/remote-runner-$version.tar.gz"}

info "Downloading remote-runner."
if ! wget -q -O $rr_file_tmp $rr_file_remote
then
	error "Error downloading remote runner [$rr_file_remote].  Either cannot download or cannot write to file [$rr_file_tmp]"
	exit 1
fi

info "Unpacking remote-runner."
if ! tar -xf $rr_file_tmp -C /tmp
then
	error "Error unpackaging tmp file [$rr_tmp_file]"
	exit 1
fi 

info "Installing to home: $rr_home" 
if ! mv /tmp/remote-runner $rr_home
then
	error "Error unpackaging tmp file [$rr_tmp_file]"
	exit 1
fi 

info "Adding env entries to: $rr_bashrc"
if ! grep -q "rr_home=$rr_home" $rr_bashrc
then
	cat - >> $rr_bashrc <<-EOF

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

info "Successfully installed remote-runner!  Please source your environment for changes to take effect."
