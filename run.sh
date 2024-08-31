#!/usr/bin/env bash

# run :: v0.0.1

function create-runfile() {
	if [[ " $* " != *' --overwrite-runfile '* ]] && [[ -e 'Runfile' ]]
	then
		echo 'Runfile already exists. To overwrite, use:'
		echo "run --overwrite-runfile"
		exit 1
	fi

	if [[ " $* " == *' --compact '* ]]
	then
cat <<EOF > Runfile
start: start app
echo "start app"
end: stop app
echo "stop app"
frontend: open frontend app
echo "open frontend app"
backend: attach to backend server
echo "attach to backend server"
repl: start shell
echo "start shell"
EOF
	else
cat <<EOF > Runfile
start: start app
	echo "start app"

end: stop app
	echo "stop app"

frontend: open frontend app
	echo "open frontend app"

backend: attach to backend server
	echo "attach to backend server"

repl: start shell
	echo "start shell"
EOF
	fi
}

function lowercase-file() {
	echo "$1" | tr '[:upper:]' '[:lower:]'
}

function uppercase-file() {
	echo "$1" | tr '[:lower:]' '[:upper:]'
}

function titlecase-file() {
	echo "$( echo "$1" | cut -c1 | tr '[:lower:]' '[:upper:]' )$( echo "$1" | cut -c2- )"
}

function smartcase-file() { local name=''
	name="$( titlecase-file "$1" )"
	[[ -d "${name}" ]] || ! [[ -e "${name}" ]] && name="$( lowercase-file "${name}" )"
	[[ -d "${name}" ]] || ! [[ -e "${name}" ]] && name="$( uppercase-file "${name}" )"
	echo "${name}"
}

function edit-file-smartcase() { local name=''
	name="$( smartcase-file "$1" )"
	if [[ " $* " != *' --noedit '* ]]
	then
		[[ " $* " == *' --confirm '* && " $* " != *' --noconfirm '* ]] && \
			read -rsn1 -p "Press any key to edit ${name} with $EDITOR · CTRL+C to exit"
		$EDITOR "${name}"
	fi
}

function print-file-smartcase() {
	cat "$( smartcase-file "$1" )"
}

function print-makefile() {
	sed -E "s|\t${vb}make --makefile ${mf} |\t${vb}make |" "$@"
}

function cd-to-nearest-file() { local lower='' upper='' title=''
	lower="$( lowercase-file "$1" )"
	upper="$( uppercase-file "$1" )"
	title="$( titlecase-file "$1" )"
	while [[ -d "./${lower}" || -d "./${upper}" || -d "./${title}" ]] || \
			! [[ -e "./${lower}" || -e "./${upper}" || -e "./${title}" ]]
	do
		if [[ "$( pwd )" != "$HOME" ]]
		then
			cd ..
		else
			echo "No ${title} found. To create one here, use:"
			echo "run --create-${lower}"
			# Note: This message pertains to the user's shell which _won't_ have
			# changed directory, because this script's main function uses a subshell.
			# So there's no need to change directory back to where we started here.
			exit 1
		fi
	done
}

function main() ( set -euo pipefail; local mf='' vb='' make_args=()
	# Handle various optional actions:
	[[ " $* " == *' --create-runfile '* || " $* " == *' --overwrite-runfile '* ]] && \
		create-runfile "$@" && edit-file-smartcase runfile --confirm "$@" && exit 0
	[[ " $* " == *' --print-runfile '* ]] && \
		cd-to-nearest-file runfile && print-file-smartcase runfile && exit 0
	[[ " $* " == *' --edit-runfile '* ]] && \
		cd-to-nearest-file runfile && edit-file-smartcase runfile "$@" && exit 0
	[[ " $* " == *' --edit-makefile '* ]] && \
		cd-to-nearest-file makefile && edit-file-smartcase makefile "$@" && exit 0

	# If no runfile in current dir, navigate up looking for one until we reach $HOME:
	cd-to-nearest-file runfile

	mf="$( mktemp )"	# Temporary makefile which we will pass to make.
	vb="@"						# Verbose - @ causes make to execute commands silently.
	make_args=()			# Arguments that will be passed on to make.

	# Handle these args which we don't want to pass on to make:
	# --verbose / -v
	for arg in "$@"
	do
		if [[ "${arg}" == '--verbose' || "${arg}" == '-v' ]]
		then
			vb="" # (verbose) Remove @ so that make prints commands before executing them.
		else
			make_args+=( "${arg}" )
		fi
	done

# ::::::::::::::::::::::::::::::::::::::::::
# Construct temporary Makefile from Runfile:
cat <<EOF > "${mf}"
h help: .usage

$(
	sed -Ee "s|^[[:space:]]*|\t${vb}|" \
			-e "s|^\t${vb}([a-zA-Z0-9_-])([a-zA-Z0-9_-]+): (.*)$|\1 \1\2: # \3|" \
			-e "s|^\t${vb}run |\t${vb}make --makefile ${mf} |" \
			-e "s|\t${vb}$|\t|" \
		Runfile
)

.usage:
	@grep -E "^[[:space:]a-zA-Z0-9_-]+: # " \$(MAKEFILE_LIST) \\
	| sed -Ee "s/^/\\t/" -e "s/: # / · /"
EOF
# Done with temporary Makefile construction.
# ::::::::::::::::::::::::::::::::::::::::::

	# --create-makefile : Write generated Makefile then exit.
	# --overwrite-makefile : Can be used to overwrite when Makefile already exists.
	if [[ " $* " == *' --create-makefile '* || " $* " == *' --overwrite-makefile '* ]]
	then
		if [[ " $* " != *' --overwrite-makefile '* ]] && [[ -e 'Makefile' ]]
		then
			echo 'Makefile already exists. To overwrite, use:'
			echo "make --overwrite-makefile"
			rm "${mf}"
			exit 1
		else
			print-makefile "${mf}" > ./Makefile
			rm "${mf}"
			exit 0
		fi
	fi

	# --print-makefile : Print generated Makefile then exit.
	if [[ " $* " == *' --print-makefile '* ]]
	then
		print-makefile "${mf}"
		rm "${mf}"
		exit 0
	fi

	# Main Path : Invoke make with generated makefile and all other arguments.
	make --makefile "${mf}" "${make_args[@]}"
	rm "${mf}"
	exit 0
)

main "$@"
