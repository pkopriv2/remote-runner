#! /bin/bash

package "vim"
package "ctags" 

file "$HOME/test" <<FILE
	permissions "644"
	contents<<CONTENTS
test file
	test file
		test file
			test file
CONTENTS
FILE

#users=( $(find /home -type d -maxdepth 1 -mindepth 1 | sed 's|^.*\/\([^\/]\+\)$|\1|') )
#for user in "${users[@]}"
#do
	#file "/home/$user/test" <<FILE
		#owner="$user"
		#group="$user"
		#permissions="644"
		#contents<<CONTENTS
#hello world

#CONTENTS
#FILE
#done
