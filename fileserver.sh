#! /bin/bash

export fileserver_port
export fileserver_pid

fileserver_port=${fileserver_port:-5001}


# Start the fileserver.  This is expecting a variable number of
# path elements.
#
fileserver_start() {
	if [[ $# -lt 1 ]]
	then
		log_error "Must supply an archive."
		exit 1
	fi

	if [[ ! -d $1 ]]
	then
		log_error "Directory [$1] doesn't exist."
		exit 1
	fi

	if [[ -n $fileserver_pid ]] 
	then
		log_error "An instance of the fileserver is already running."
		exit 1
	fi

	cat -> /tmp/fileserver.rb <<EOF
require 'socket' 

base_path="$1"
base_path=base_path.gsub(/\/$/, '')

server = TCPServer.open($fileserver_port)   
while true 
	Thread.start(server.accept) do |client|
		file = client.readline.chop

		puts "Processing download: #{file}"

		full_path="#{base_path}/#{file}"

	 	unless File.exists?(full_path)
			puts "No such file exists: #{full_path}"
			client.close()
		end

		client.send IO.read(full_path), 0
		client.close
	end
end	

EOF
	# Start the fileserver
	ruby /tmp/fileserver.rb &

	fileserver_pid=$!
	if [[ -z $fileserver_pid ]] 
	then
		log_error "Unable to start fileserver."
		exit 1
	fi

	trap fileserver_stop INT TERM EXIT
}

fileserver_stop() {
	kill $fileserver_pid 2>/dev/null
	wait $fileserver_pid 2>/dev/null
	unset -v fileserver_pid 
	trap - INT TERM EXIT
	rm -f /tmp/fileserver.rb
}
