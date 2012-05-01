# Gets the ip of the host.  Expecting the output of
# the host command to be:
#  	pkopriv2-fileserver has address 192.168.100.3
# 
host_get_ip() {
	expr "$(host $1)" : "^$1 has address \(.*\)$"
}
