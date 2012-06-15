install_dir=$(dirname $0)

if ! echo $install_dir | grep -q '^\/' 
then 
	install_dir="$(echo $install_dir | sed -e 's/^\.//')"
	install_dir="$(pwd)/$install_dir"
fi


cat - > ~/.profile.d/rr.sh <<-EOF
#! /bin/bash

export rr_home=$install_dir

source $install_dir/env.sh
source $install_dir/completions.sh

PATH=\$PATH:$install_dir/bin
EOF
