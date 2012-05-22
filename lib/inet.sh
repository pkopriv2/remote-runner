#! /bin/bash

# Given an interface, get the inet address associated 
# with it.
#
#
inet_get_addr() {
	ifconfig $1 | grep 'inet addr:' | awk '{print $2;}' | sed 's/addr://'			
}

# Given an ip address, determine the primary interface
# that will route the given address.
#
#
inet_get_iface() {
	if [[ $(expr "$1" : "^[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\$") == 0 ]]
	then 
		ip=$(host_get_ip "$1")
	fi

	ip route get $ip | head -n 1 | awk '{print $3;}'
}

# Given a destination address, this function returns the
# ip address of the interface that will be used to route
# ip packets to that address.
#
#
inet_src_ip() {
	if [[ $(expr "$1" : "^[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\$") == 0 ]]
	then 
		ip=$(host_get_ip "$1")
	fi

	ip route get $ip | head -n 1 | awk '{print $5;}'
}
