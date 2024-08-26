#!/usr/bin/env bash

# run :: v1.0.0

set -euo pipefail

function run {
	local mf vb make_args

	mf="$( mktemp )" # makefile
	vb="@"           # verbose - @ causes make to execute commands silently
	make_args=( --makefile "${mf}" ) # arguments that will be passed on to make

	for arg in "$@"
	do
		if [[ "${arg}" == '--verbose' || "${arg}" == '-v' ]]
		then
			vb="" # verbose - remove @ so that make prints commands before executing them
		else
			make_args+=( "${arg}" )
		fi
	done

cat <<EOF > "${mf}"
h help :: .usage

$(
	sed -Ee "s~^[[:space:]]*~\t${vb}~" \
			-e "s~^\t${vb}([a-zA-Z0-9])([a-zA-Z0-9]+) :: (.*)$~\1 \1\2 :: # \3~" \
			-e "s~^\t${vb}run ~\t${vb}make --makefile ${mf} ~" \
			-e "s~\t${vb}$~\t~" \
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
			rm "${mf}"
			exit 1
		fi
		sed -E "s~\t${vb}make --makefile ${mf} ~\t${vb}make ~" "${mf}" > ./Makefile
	else
		make "${make_args[@]}"
	fi

	rm "${mf}"
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

