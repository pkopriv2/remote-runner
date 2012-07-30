#! /bin/bash

require "lib/log.sh"

declare -a callbacks=( on_condition on_change on_error on_success )

for callback in "${callbacks[@]}"
do
	src=$(
		cat -<<-EOF
			$callback() {
				if [[ -z \$1 ]]
				then
					local src_$callback=\$(cat -)
				else
					local src_$callback=\$1
				fi

				local src=\$(
					cat - <<-SRCMARKER
						callback_$callback() {
							\$src_$callback 
							$callback "echo &> /dev/null"
						}
					SRCMARKER
				)

				eval "\$src" 
			}

			$callback "echo &> /dev/null"
		EOF
	); eval "$src"
done
