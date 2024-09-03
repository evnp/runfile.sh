#!/usr/bin/env bash

# run :: v0.0.1

function create-runfile() { local buffer=''
	if [[ " $* " != *' --overwrite-runfile '* ]] && [[ -e 'Runfile' ]]
	then
		echo 'Runfile already exists. To overwrite, use:'
		echo 'run --overwrite-runfile'
		exit 1
	fi

	buffer="$( cat <<EOF
s start: stop # start app
	run build env=dev # tasks can be run directly from other tasks
	echo "starting app"

stop: # stop app
	echo "stopping app"

b build: lint # build app for environment [vars: env]
	[[ -n \$(env) ]] && echo "buiding app for \$(env)" || echo "error: missing env"

t test: build # run all tests or specific tests [vars: name1, name2, etc.]
	[[ -n \$(@) ]] && echo "running tests \$(@)" || echo "running all tests"

l lint: # lint all files or specific file [vars: file]
	[[ -n \$(1) ]] && echo "linting file \$(1)" || echo "linting all files"
EOF
)"

	if [[ " $* " == *' --compact '* ]]
	then
		echo "${buffer}" | sed -e '/^$/d' -e 's/^\t//' > Runfile
	else
		echo "${buffer}" > Runfile
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
	! [[ -e "${name}" && ! -d "${name}" ]] && name="$( lowercase-file "${name}" )"
	! [[ -e "${name}" && ! -d "${name}" ]] && name="$( uppercase-file "${name}" )"
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
	sed -E "s!\t${at}make --makefile ${makefile} !\t${at}make !" "$@"
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

function main() ( set -euo pipefail
	local makefile='' buffer='' at='' cmd=''
	local arg='' make_args=() cmd_args=() pos_args=() pos_arg_idx=0

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

	# Local values:
	makefile="$( mktemp )"	# Temporary makefile which we will pass to make.
	at="@"									# @-prefix causes make to execute commands silently.

	# Handle these args which we don't want to pass on to command:
	# --print-command, --dry-run-command,
	# --overwrite-runfile, --overwrite-makefile,
	# --create-runfile, --create-makefile,
	# --print-runfile, --print-makefile,
	# --edit-runfile, --edit-makefile,
	for arg in "$@"
	do
		if [[ "${arg}" == '--print-command' || "${arg}" == '--dry-run-command' ]]
		then
			at="" # Remove @-prefix so that make prints commands before executing them.
		elif ! [[ "${arg}" == '--overwrite-runfile' || "${arg}" == '--overwrite-makefile' ]] \
			&& ! [[ "${arg}" == '--create-runfile' || "${arg}" == '--create-makefile' ]] \
			&& ! [[ "${arg}" == '--print-runfile' || "${arg}" == '--print-makefile' ]] \
			&& ! [[ "${arg}" == '--edit-runfile' || "${arg}" == '--edit-makefile' ]]
		then
			if [[ -z "${cmd}" ]]
			then
				cmd="${arg}"
			elif [[ " ${arg}" == *' -' ]]
			then
				make_args+=( "${arg}" )
			elif [[ "${arg}" =~ ^[a-zA-Z0-9_-]+\= ]]
			then
				cmd_args+=( "${arg}" )
			else
				pos_args+=( "${arg}" )
			fi
		fi
	done

# ::::::::::::::::::::::::::::::::::::::::::
# Construct temporary Makefile from Runfile:
cat <<EOF> "${makefile}"
.PHONY: _tasks
_tasks: .tasks
$(
	sed -E \
		-e "s!^[[:space:]]*!\t${at}!" \
		-e "s!^\t${at}([a-zA-Z0-9 _-]+):([a-zA-Z0-9 _-]+)?#(.*)\$!\n.PHONY: \1\n\1:\2#\3!" \
		-e "s!^\t${at}\$!!" \
		Runfile | cat -s
)

.PHONY: .tasks
.tasks:
	@grep -E "^[a-zA-Z0-9 _-]+:[a-zA-Z0-9 _-]*#" \$(MAKEFILE_LIST) \\
	| sed -Ee 's/^/\\t/' -e "s/[ ]*:[a-zA-Z0-9 _-]*#[ ]*/ · /"
EOF
# Done with temporary Makefile construction.
# ::::::::::::::::::::::::::::::::::::::::::

	# Handle positional command arguments if any were provided:
	if [[ " $* " != *' --print-makefile '* ]] \
		&& [[ " $* " != *' --create-makefile '* ]] \
		&& [[ " $* " != *' --overwrite-makefile '* ]]
	then
		buffer="$( cat "${makefile}" )"
		# Cases where no named or positional arguments were provided:
		# Replace $(var) $(@) $(1) $(2) etc. in script with empty backtick expression ``.
		# This seems odd, but it allows tasks like: [[ -n $(1) ]] && echo "$1"
		# to work whether or not $1 positional arg was provided. Without it, make will
		# error out due to the script being interpreted as [[ -n  ]]. With standard
		# quotes instead of backticks, expressions like echo "$1" will inadvertently
		# print the quotes.
		if ! (( ${#cmd_args[@]} ))
		then
			# Case where no named arguments were provided: replace $(abc) $(xyz) etc.
			# Note: There must be at least one lowercase letter [a-z] in these matches,
			#				because otherwise we'd replace built in Make vars like $(MAKEFILE_LIST)
			# 			which we want to leave alone.
			buffer="$( echo "${buffer}" | sed -E 's!\$\([a-zA-Z0-9_]*[a-z][a-zA-Z0-9_]*\)!``!g' )"
		fi
		if ! (( ${#pos_args[@]} ))
		then
			# Case where no positional arguments were provided: replace $(@) $(1) $(2) etc.
			buffer="${buffer//\$([0-9@])/\`\`}"
		else
			# Replace $(@) in script with concatenation of all positional args:
			buffer="${buffer//\$(@)/${pos_args[*]}}"
			# Replace $(1) $(2) etc. in script with each individual positional arg:
			for arg in "${pos_args[@]}"
			do
				(( pos_arg_idx++ )) || true
				buffer="${buffer//\$(${pos_arg_idx})/${arg}}"
			done
		fi
		# Write buffer back to temporary makefile:
		echo "${buffer}" > "${makefile}"
	fi

	# --create-makefile : Write generated Makefile, open in editor (optional) then exit.
	# --overwrite-makefile : Can be used to overwrite when Makefile already exists.
	if [[ " $* " == *' --create-makefile '* || " $* " == *' --overwrite-makefile '* ]]
	then
		if [[ " $* " != *' --overwrite-makefile '* ]] \
		&& [[ -e 'Makefile' && ! -d 'Makefile' ]]
		then
			echo 'Makefile already exists. To overwrite, use:'
			echo 'make --overwrite-makefile'
			rm "${makefile}"
			exit 1
		else
			if grep -qE '\$\([@0-9]\)' "${makefile}"
			then
				echo "Warning: Your runfile uses positional args \$(@) \$(1) \$(2) etc."
				echo "which aren't compatible with Make. You'll need to update these"
				echo "commands to accept standard Make-style named arguments:"
				echo "\$(abc) in your Makefile, passed to task as: $ make task abc=xyz"
				echo
			fi
			print-makefile "${makefile}" > ./Makefile
			rm "${makefile}"
			edit-file-smartcase makefile --confirm
			exit 0
		fi
	fi

	# --print-makefile : Print generated Makefile then exit.
	if [[ " $* " == *' --print-makefile '* ]]
	then
		print-makefile "${makefile}"
		rm "${makefile}"
		exit 0
	fi

	# Main Path : Invoke make with generated makefile and all other arguments.
	if [[ " $* " == *' --dry-run-command '* ]]
	then
		make_args+=( --dry-run "${cmd}" )
	elif [[ -n "${cmd}" ]]
	then
		make_args+=( "${cmd}" )
	fi
	if (( ${#cmd_args[@]} ))
	then
		make_args+=( -- "${cmd_args[@]}" )
	fi

	make --makefile "${makefile}" "${make_args[@]}"

	# Clean up temporary Makefile and exit with success:
	rm "${makefile}"
	exit 0
)

main "$@"
