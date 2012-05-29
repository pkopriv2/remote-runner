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
		ip=$(inet_host_ip "$1")
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
		ip=$(inet_host_ip "$1")
	fi

	ip route get $ip | head -n 1 | sed 's|.*src \([^ ]\+\)|\1|'
}


# Gets the ip of the host.  Expecting the output of
# the host command to be:
#  	pkopriv2-fileserver has address 192.168.100.3
# 
inet_host_ip() {
	expr "$(host $1)" : "^$1 has address \(.*\)$"
}
