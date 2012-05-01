#! /bin/bash

# Creates the directory if it doesn't already exist.
#
dir_create_if_missing() {
	if [[ ! -d "$1" ]] 
	then 
		mkdir "$1"
	fi
}
