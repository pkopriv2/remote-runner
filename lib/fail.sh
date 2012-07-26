# Logs an error message and shows a simple stacktrace.  
fail() {
	echo "An error occurred: $1" 1>&2

	local frame=0
	while true 
	do
		if ! caller $frame 1>&2
		then
			break
		fi

		let frame=frame+1 # (( frame++ )) will trigger an error.
	done

	exit 1
}
