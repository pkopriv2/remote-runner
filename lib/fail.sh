# Logs an error message and shows a simple stacktrace.  
fail() {
	echo "An error occurred: $1" 1>&2

	local frame=0
	while caller $frame; do
		((frame++));
	done

	exit 1
}

## Taken from: http://stackoverflow.com/questions/3338030/multiple-bash-traps-for-the-same-signal
## appends a command to a trap
##
## - 1st arg:  code to add
## - remaining args:  names of traps to modify
##
#trap_add() {
    #trap_add_cmd=$1; shift || fatal "${FUNCNAME} usage error"
    #for trap_add_name in "$@"; do
        #trap -- "$(
            #extract_trap_cmd() { printf '%s\n' "$3"; }

            #eval "extract_trap_cmd $(trap -p "${trap_add_name}")"

            #printf '%s\n' "${trap_add_cmd}"
        #)" "${trap_add_name}" \
            #|| fail "unable to add to trap ${trap_add_name}"
    #done
#}
