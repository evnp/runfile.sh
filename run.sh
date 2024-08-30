#!/usr/bin/env bash

# run :: v0.0.1

function create-runfile() {
	if [[ -f './Runfile' ]]
	then
		echo 'Runfile already exists.'
		exit 1
	fi

	if [[ " $* " == *' --compact '* ]]
	then
cat <<EOF > Runfile
start: start app
echo "start app"
end: stop app
echo "stop app"
client: open client
echo "open client"
server: attach to server
echo "attach to server"
repl: start shell
echo "start shell"
EOF
	else
cat <<EOF > Runfile
start: start app
  echo "start app"

end: stop app
  echo "stop app"

client: open client
  echo "open client"

server: attach to server
  echo "attach to server"

repl: start shell
  echo "start shell"
EOF
	fi
}

function lowercase-file() {
	echo "$1" | tr [A-Z] [a-z]
}

function uppercase-file() {
	echo "$1" | tr [a-z] [A-Z]
}

function titlecase-file() {
  echo "$( echo "$1" | cut -c1 | tr [a-z] [A-Z] )$( echo "$1" | cut -c2- )"
}

function smartcase-file() { local name=''
	name="$( titlecase-file "$1" )"
	! [[ -f "${name}" ]] && name="$( lowercase-file "${name}" )"
	! [[ -f "${name}" ]] && name="$( uppercase-file "${name}" )"
	echo "${name}"
}

function print-file() {
	cat "$( smartcase-file "$1" )"
}

function edit-file() { local name=''
	name="$( smartcase-file "$1" )"
	if [[ " $* " != *' --noedit '* ]]
	then
		[[ " $* " == *' --confirm '* && " $* " != *' --noconfirm '* ]] && \
			read -rsn1 -p "Press any key to edit ${name} with $EDITOR · CTRL+C to exit"
		$EDITOR "${name}"
	fi
}

function cd-to-nearest-file() { local lower='' upper='' title=''
	lower="$( lowercase-file "$1" )"
	upper="$( uppercase-file "$1" )"
	title="$( titlecase-file "$1" )"
	while ! [[ -f "./${lower}" || -f "./${upper}" || -f "./${title}" ]]
	do
		if [[ "$( pwd )" == "$HOME" ]]
		then
			echo "No ${title} found."
			echo "Use `run --create-${lower}` to create one here."
			exit 1
		fi
		cd ..
	done
}

function main() ( set -euo pipefail; local mf='' vb='' make_args=()
	# Handle various optional actions:
	[[ " $* " == *' --create-runfile '* ]] && \
		create-runfile "$@" && edit-file runfile --confirm "$@" && exit 0
	[[ " $* " == *' --print-runfile '* ]] && \
		cd-to-nearest-file runfile && print-file runfile && exit 0
	[[ " $* " == *' --edit-runfile '* ]] && \
		cd-to-nearest-file runfile && edit-file runfile "$@" && exit 0
	[[ " $* " == *' --edit-makefile '* ]] && \
		cd-to-nearest-file makefile && edit-file makefile "$@" && exit 0

	cd-to-nearest-file Runfile

	mf="$( mktemp )" # makefile
	vb="@"					 # verbose - @ causes make to execute commands silently
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
	sed -Ee "s|^[[:space:]]*|\t${vb}|" \
			-e "s|^\t${vb}([a-zA-Z0-9_-])([a-zA-Z0-9_-]+): (.*)$|\1 \1\2 :: # \3|" \
			-e "s|^\t${vb}run |\t${vb}make --makefile ${mf} |" \
			-e "s|\t${vb}$|\t|" \
		Runfile
)

.usage:
	@grep -E "^[^@]*:.*#" \$(MAKEFILE_LIST) | sed -E "s/(.*):(.*):.*#(.*)/	\\1·\\2\\3/"
EOF

	if [[ " $* " == *' --write-makefile '* || " $* " == *' --overwrite-makefile '* ]]
	then
		if ! [[ " $* " == *' --overwrite-makefile '* ]] && [[ -f 'Makefile' ]]
		then
			echo "Makefile already exists. Run again with --overwrite-makefile to overwrite."
			rm "${mf}"
			exit 1
		fi
		sed -E "s|\t${vb}make --makefile ${mf} |\t${vb}make |" "${mf}" > ./Makefile
		rm "${mf}"
		exit 0
	fi

	# Print generated Makefile then exit:
	if [[ " $* " == *' --print-makefile '* ]]
	then
		sed -E "s|\t${vb}make --makefile ${mf} |\t${vb}make |" "${mf}"
		rm "${mf}"
		exit 0
	fi

	make "${make_args[@]}"
	rm "${mf}"
	exit 0
)

main "$@"
