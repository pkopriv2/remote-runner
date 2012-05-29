array_contains () { 
	for e in "${@:2}"
	do 
		if [[ "$e" == "$1" ]]
		then
			return 0;
		fi
	done 

	return 1
}

array_print() {
	echo -n "( "

	for e in "${@}"
	do 
		echo -n "$e "
	done 

	echo ")"
}
