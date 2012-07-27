PATH=$PATH:$rr_home/bin

for script in $rr_home/env/*.sh
do
	if [[ -f $script ]] 
	then
		source $script
	fi
done
