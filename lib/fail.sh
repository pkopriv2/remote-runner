# Logs an error message and shows a simple stacktrace.  
fail() {
	echo "An error occurred: $*" 1>&2

	local frame=0
	while caller $frame; do
		((frame++));
	done

	exit 1
}
