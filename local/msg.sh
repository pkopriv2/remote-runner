info() {
	if ! tput setaf &> /dev/null
	then
		echo -e "$1"
	else
		echo -e "$(tput setaf 2)$1$(tput sgr0)"
	fi
}

error() {
	if ! tput setaf &> /dev/null
	then
		echo -e "$1 >&2"
	else
		echo -e "$(tput setaf 1)$1$(tput sgr0)"
	fi
}
