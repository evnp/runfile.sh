#!/usr/bin/env bash

# run :: v1.0.0

set -euo pipefail

function run {
	local makefile
	makefile="$( mktemp )"

cat <<EOF > "${makefile}"
h help :: .usage

$(
	sed -Ee 's~^[[:space:]]*~\t@~' \
			-e 's~^\t@([a-zA-Z0-9])([a-zA-Z0-9]+) :: (.*)$~\1 \1\2 :: # \3~' \
			-e "s~^\t@run ~\t@make --makefile ${makefile} ~" \
			-e 's~@$~~' \
		Runfile
)

.usage:
	@grep -E "^[^@]*:.*#" \$(MAKEFILE_LIST) | sed -E "s~(.*):(.*):.*#(.*)~	\\1·\\2\\3~"
EOF

	if [[ " $* " == *' --write-makefile '* || " $* " == *' --overwrite-makefile '* ]]
	then
		if ! [[ " $* " == *' --overwrite-makefile '* ]] && [[ -f 'Makefile' ]]
		then
			echo "Makefile already exists. Run again with --overwrite-makefile to overwrite."
			rm "${makefile}"
			exit 1
		fi
		sed -E "s~@make --makefile ${makefile} ~@make ~" "${makefile}" > ./Makefile
	else
		make --makefile "${makefile}" "$@"
	fi

	rm "${makefile}"
	exit 0
}

run "$@"

# Example Runfile (recommended formatting):
# ```
# start :: start app
#   mix start
#
# kill :: kill app
#   mix stop
#
# repl :: start shell
#   iex -S mix
# ```
# Example Runfile (compact formatting):
# ```
# start :: start app
# mix start
# kill :: kill app
# mix stop
# repl :: start shell
# iex -S mix
# ```
# $ run
#     s start · start app
#     k kill · kill app
#     r repl · start shell

