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

version=$(cat $rr_home/project.txt | awk '{print $2;}')

info "Packaging version: $version" 

mkdir -p $rr_home/target

griswold -o $rr_home/target/remote-runner-$version.tar.gz \
         -c $rr_home                                      \
		 -b remote-runner                                 \
		  bin                                             \
		  dsl                                             \
		  env                                             \
		  lib                                             \
		  scripts                                         \
		  env.sh                                          \
		  require.sh                                      
