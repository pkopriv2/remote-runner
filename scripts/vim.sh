#! /bin/bash

package "vim"
package "ctags" 


file "/home/pkopriv2/test" <<FILE
		owner="pkopriv2"
		group="pkopriv2"
		permissions="644"
		contents<<CONTENTS
hello world
CONTENTS
FILE
