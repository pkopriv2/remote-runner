# See if rr_home has been set.  If not, try to find it.
if [[ -z $rr_home ]]
then
	export rr_home=$HOME/.rr		
fi

PATH=$PATH:$rr_home/bin

for script in $rr_home/env/*.sh
do
	if [[ -f $script ]] 
	then
		source $script
	fi
done
