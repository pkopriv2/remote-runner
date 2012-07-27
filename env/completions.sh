export rr_home=${rr_home:-$HOME/.rr}
export rr_host_home=${rr_host_home:-$rr_home/hosts}
export rr_archive_home=${rr_archive_home:-$rr_home/archives}
export rr_role_home=${rr_role_home:-$rr_home/roles}

_rrcd_complete() {
	local cur=${COMP_WORDS[COMP_CWORD]}
	local prev=${COMP_WORDS[COMP_CWORD-1]}

	COMPREPLY=()   

	case "$prev" in
		rrcd) 
			local archives=( $(builtin cd "$rr_archive_home" ; find . -maxdepth 1 -mindepth 1 | sed 's|^\.\/||' | sort ) )
			COMPREPLY=( $( compgen -W "${archives[@]}" -- $cur ) )
			;;
	esac
	return 0
}

complete -F _rrcd_complete rrcd

_rr_complete() {
	local cur=${COMP_WORDS[COMP_CWORD]}
	local cmd=""
	local index=1
	while (( index < COMP_CWORD )) 
	do
		cmd+=":${COMP_WORDS[index]}"
		(( index++ ))
	done

	COMPREPLY=()   

	case "$cmd" in
		"") 
			local hosts=($(builtin cd "$rr_host_home" ; find . -maxdepth 1 -mindepth 1 -name '*.sh' -print | sed 's|\.\/||' | sed 's|\.sh||' | sort ))
			COMPREPLY=( $( compgen -W '${hosts[@]} archive host key role' -- $cur ) )
			;;
		#:rr:-) 
			#COMPREPLY=( $( compgen -W '-a -l -p' -- $cur ) )
			#;;
		:archive)
			COMPREPLY=( $( compgen -W 'create delete install list' -- $cur ) )
			;;
		:archive:delete)
			local archives=( $(builtin cd "$rr_archive_home" ; find . -maxdepth 1 -mindepth 1 | sed 's|^\.\/||' | sort ) )
			COMPREPLY=( $( compgen -W '${archives[@]}' -- $cur ) )
			;;
		:host)
			COMPREPLY=( $( compgen -W 'show list edit bootstrap' -- $cur ) )
			;;
		:host:show|:host:edit)
			local hosts=($(builtin cd "$rr_host_home" ; find . -maxdepth 1 -mindepth 1 -name '*.sh' -print | sed 's|\.\/||' | sed 's|\.sh||' | sort ))
			COMPREPLY=( $( compgen -W '${hosts[@]}' -- $cur ) )
			;;
		:key)
			COMPREPLY=( $( compgen -W 'create delete list show' -- $cur ) )
			;;
		:key:show|:key:delete)
			local keys=($(builtin cd "$rr_key_home" ; find . -maxdepth 1 -mindepth 1 -name 'id_rsa.*.pub' -print | sed 's|\.\/id_rsa\.\([^\.]*\)\.pub|\1|' | sort ))
			COMPREPLY=( $( compgen -W '${keys[@]}' -- $cur ) )
			;;
		:role)
			COMPREPLY=( $( compgen -W 'create delete list show edit' -- $cur ) )
			;;
		:role:show|:role:delete|:role:edit)
			local roles=($(builtin cd "$rr_role_home" ; find . -maxdepth 1 -mindepth 1 -name '*.sh' -print | sed 's|\.\/||' | sed 's|\.sh||' | sort ))
			COMPREPLY=( $( compgen -W '${roles[@]}' -- $cur ) )
			;;
	esac
	return 0
}

complete -F _rr_complete rr 
complete -F _rr_complete rrsudo
