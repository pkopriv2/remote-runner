# Remote-Runner

Remote-runner is a tool to automate the remote configurationa and management of servers.   Think 
[Chef](http://www.opscode.com/chef/) only without the bloat.  

Written completely in bash, remote-runner's simplistic DSL is as near to the OS as possible.  The
remote scripts are written in bash, but give bindings for executing arbitrary language scripts - giving
you the flexibility you need.  Best of all, remote-runner requires no installation on *any* remote 
system - only SSH is required and a base Posix compliant system!

# Commands

* *rr* - The main remote-runner script. Most of the features are located as sub-commands of this program.
* *rrd* - The daemonized form of rr.  Will run rr subcommands on a regular interval, with extra error checking.
* *rrc* - An alias to "rr cmd".
* *rrr* - An alias to "rr run". 
* *griswold* - A tar wrapper that facilitates in the packaging of files.

# Installation

* Install the current version.
	
	curl https://raw.github.com/pkopriv2/remote-runner/master/install.sh | bash -s 

* Install a specific version.

	curl https://raw.github.com/pkopriv2/remote-runner/master/install.sh | bash -s "1.0.1"

# Usage

1. Create an ssh public/private key pair.
	
	rr key create home

2. Bootstrap a host with the key.

	rr host boostrap root@localhost home

3. Create an archive (This is a repo for remote scripts)

	pushd ~
	rr archive create test
	rr archive install test
	popd

4. Edit the archive

	rrcd test
	cat - > scripts/default.sh <<-EOF
	log_info "Hello, world.  I am on \$HOSTNAME!"

	file "~/test.txt"<<-FILE
		contents "hello, world"
	FILE
	EOF

5. Run the archive!

	rrr --host root@localhost --archive test 
