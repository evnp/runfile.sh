#!/usr/bin/env bash

# runfile.sh · v0.0.2

function version() {
	head -n 3 < "$0" | tail -1 | cut -c3-
}

function usage() {
cat <<EOF

· $( version ) ·

· Language-agnostic project task runner · Missing companion of the ubiquitous Make ·
· Use a Runfile on its own to manage project tasks · start, build, test, lint, etc ·
· Use Runfile & Makefile in tandem to keep project tasks and build steps organized ·

· Usage · run ····················· Print all available tasks.
          run [options] [task] ···· Run a task.
          run [options] [action] ·· Run a Runfile/Makefile action.
                                  · Task is ignored if action is specified.
  # ./Runfile syntax:
  taskabc: # task description
    shell command(s) for task abc
  taskxyz: taskabc # task description · taskxyz runs taskabc first just like Make would
    shell command(s) for task xyz

  ^ Whitespace doesn't matter; tabs, spaces, blank lines are all ok, or may be omitted.

· Actions ·

--runfile-help --runfile-usage ·· Print this usage documentation then exit.
--runfile-version ··············· Print current runfile.sh version then exit.

--runfile ··· Print contents of nearest Runfile (in current dir or dir above).
--makefile ·· Print contents of Makefile which will be generated from nearest Runfile.

--runfile-edit ··· Open nearest Runfile with \$EDITOR (in current dir or dir above).
--makefile-edit ·· Open nearest Makefile with \$EDITOR (in current dir or dir above).

--runfile-create  --runfile-write ··· Write template Runfile in current dir.
--makefile-create --makefile-write ·· Write generated Makefile in current dir.

--runfile-overwrite ··· Overwrite existing Runfile with template Runfile.
--makefile-overwrite ·· Overwrite existing Makefile with generated Makefile.

· Options ·

--runfile-compact ···· Use "compact" formatting for Runfile when creating or printing.
--runfile-confirm ···· Always ask for confirmation before opening files with \$EDITOR.
--runfile-noconfirm ·· Never ask for confirmation before opening files with \$EDITOR.
--runfile-noedit ····· Never open files with \$EDITOR.
--runfile-verbose ···· Print code line-by-line to terminal during task execution.

--make-dry-run ·· Don't execute task code, just print line-by-line to terminal instead.
--make-* ········ Pass any argument directly to they underlying Make command
                · by prefixing the intended Make argument with "--make-".
                · For example, --make-dry-run will pass --dry-run to Make.
EOF
}

function create-runfile() { local buffer=''
	if [[ " $* " != *' --runfile-overwrite '* ]] && [[ -e 'Runfile' ]]
	then
		echo 'Runfile already exists. To overwrite, use:'
		echo 'run --overwrite-runfile'
		exit 1
	fi

optionally-compact-file "$@" <<EOF > Runfile
s start: stop # start app
  run build env=dev # tasks can be run directly from other tasks
  echo "starting app"

stop: # stop app
  echo "stopping app"

b build: lint # build app for environment [vars: env]
  [[ -n \$(env) ]] && echo "buiding app for \$(env)" || echo "error: missing env"

t test: # run all tests or specific tests [vars: name1, name2, etc.]
  run build env=test
  [[ -n \$(@) ]] && echo "running tests \$(@)" || echo "running all tests"

l lint: # lint all files or specific file [vars: file]
  [[ -n \$(1) ]] && echo "linting file \$(1)" || echo "linting all files"
EOF
}

function compact-file() {
	sed -e '/^$/d' -e 's/^[[:space:]]//'
}

function optionally-compact-file() {
	if [[ " $* " == *' --runfile-compact '* ]]
	then
		compact-file
	else
		cat
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
	if [[ " $* " != *' --runfile-noedit '* ]]
	then
		[[ " $* " == *' --runfile-confirm '* ]] && \
		[[ " $* " != *' --runfile-noconfirm '* ]] && \
			read -rsn1 -p "Press any key to edit ${name} with $EDITOR · CTRL+C to exit"
		$EDITOR "${name}"
	fi
}

function print-file-smartcase() {
	optionally-compact-file "$@" < "$( smartcase-file "$1" )"
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
			echo "run --${lower}-create"
			# Note: This message pertains to the user's shell which _won't_ have
			# changed directory, because this script's main function uses a subshell.
			# So there's no need to change directory back to where we started here.
			exit 1
		fi
	done
}

function main() ( set -euo pipefail
	local makefile='' buffer='' at='' task=''
	local arg='' make_args=() named_args=() pos_args=() pos_arg_idx=0

	# --runfile-help, --runfile-usage | Print usage documentation then exit.
	# --runfile-version               | Print current runfile.sh version then exit.
	[[ " $* " == *' --runfile-help '* ]] || \
	[[ " $* " == *' --runfile-usage '* ]] && usage && exit 0
	[[ " $* " == *' --runfile-version '* ]] && version | cut -dv -f2 && exit 0

	# --runfile-create    | Write template Runfile, then open in editor (optional).
	# --runfile-write     | Alias for --runfile-create.
	# --runfile-overwrite | Can be used to overwrite when Runfile already exists.
	[[ " $* " == *' --runfile-create '* ]] || \
	[[ " $* " == *' --runfile-write '* ]] || \
	[[ " $* " == *' --runfile-overwrite '* ]] && \
		create-runfile "$@" && edit-file-smartcase runfile --runfile-confirm "$@" && exit 0

	# --runfile-edit  | Edit current Runfile, or exit with error if not found.
	# --makefile-edit | Edit current Makefile, or exit with error if not found.
	[[ " $* " == *' --runfile-edit '* ]] && \
		cd-to-nearest-file runfile && edit-file-smartcase runfile "$@" && exit 0
	[[ " $* " == *' --makefile-edit '* ]] && \
		cd-to-nearest-file makefile && edit-file-smartcase makefile "$@" && exit 0

	# --runfile | Print current Runfile, or exit with error if not found.
	[[ " $* " == *' --runfile '* ]] || \
	[[ "$*" == '--runfile-compact' ]] && \
		cd-to-nearest-file runfile && print-file-smartcase runfile "$@" && exit 0

	# If no Runfile in current dir, navigate up looking for one until we reach $HOME:
	cd-to-nearest-file runfile

	# Temporary Makefile which we will pass to make:
	makefile="$( mktemp )"

	# @-prefix causes Make to execute tasks silently (without printing task code):
	at="@"
	[[ " $* " == *' --runfile-verbose '* || " $* " == *' --make-dry-run '* ]] && \
		at="" # Remove @-prefix so that Make prints task code before executing tasks.

	# Separate arguments into categories:
	# make_args  : Arguments that will be passed on to Make.
	# named_args : name=value arguments interpolated into $(name) within task code.
	# pos_args   : Arguments interpolated into $(1) $(2) $(3) etc. within task code.
	#            : All positional args will be interpoated into $(@), space-separated.
	for arg in "$@"
	do
		if [[ "${arg}" == '--make-'* ]]
		then
			make_args+=( "${arg/make-}" )
		elif [[ "${arg}" =~ ^[a-zA-Z0-9_-]+\= ]]
		then
			named_args+=( "${arg}" )
		elif [[ "${arg}" != '--runfile-'* ]]
		then
			if [[ -z "${task}" ]]
			then
				task="${arg}"
			elif [[ "${arg}" != '--runfile-'* ]]
			then
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

	# Process interpolated args within generated Makefile: $(arg) $(@) $(1) $(2) etc.
	if [[ " $* " != *' --makefile '* ]] && \
		[[ " $* " != *' --makefile-create '* ]] && \
		[[ " $* " != *' --makefile-write '* ]] && \
		[[ " $* " != *' --makefile-overwrite '* ]]
		# If outputting Makefile, skip this section.
	then
		buffer="$(
			sed -E 's!(\$\((@|[0-9]+|[a-zA-Z][a-zA-Z0-9_]*)\))!\`printf '"'%s' '\1'"'\`!g' \
				"${makefile}"
		)"
		# Wrap all Runfile argument patterns in printf, eg. $(@) -> `printf '%s' '$(@)'`
		# This resolves issues with Make arg-handling behavior when args are omitted.
		# For example: [[ -n $(arg) ]] && echo "${arg}"
		# This will error if $(arg) is not specified, because Make executes: [[ -n  ]]
		# With printf-wrapping: [[ -n `printf '%s' '$(arg)'` ]] && echo "${arg}"
		# Now if $(arg) is not specified, Make executes: [[ -n `printf '%s' ''` ]]
		# which is perfectly valid. We can't simply wrap args in quotes, because then
		# the quotes would be included when args are interpolated within strings. eg.
		# "hello: $(world)" -> "hello: '$(world)'" -> "hello: ''" (unwanted quotes)

		# Replace $(@) in script with concatenation of all positional args:
		buffer="${buffer//\$(@)/${pos_args[*]}}"
		# Note: Perform this replacement even if no positional args were provided,
		# because otherwise default Make behavior interpolates ${task} in place of $(@).

		# Replace $(1) $(2) etc. in script with each individual positional arg:
		for arg in "${pos_args[@]}"
		do
			(( pos_arg_idx++ )) || true
			buffer="${buffer//\$(${pos_arg_idx})/${arg}}"
		done

		# Write buffer back to temporary makefile:
		echo "${buffer}" > "${makefile}"
	fi

	# --makefile-create    | Write generated Makefile, then open in editor (optional).
	# --makefile-write     | Alias for --makefile-create.
	# --makefile-overwrite | Can be used to overwrite when Makefile already exists.
	if [[ " $* " == *' --makefile-create '* ]] || \
		[[ " $* " == *' --makefile-write '* ]] || \
		[[ " $* " == *' --makefile-overwrite '* ]]
	then
		if [[ " $* " != *' --makefile-overwrite '* ]] \
		&& [[ -e 'Makefile' && ! -d 'Makefile' ]]
		then
			echo 'Makefile already exists. To overwrite, use:'
			echo 'make --makefile-overwrite'
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
			edit-file-smartcase makefile --runfile-confirm
			exit 0
		fi
	fi

	# --makefile | Print generated Makefile then exit:
	if [[ " $* " == *' --makefile '* ]]
	then
		print-makefile "${makefile}"
		rm "${makefile}"
		exit 0
	fi

	# Main Path | Prepare arguments to be passed to Make:
	if [[ -n "${task}" ]]
	then
		make_args+=( "${task}" )
	fi
	if (( ${#named_args[@]} ))
	then
		make_args+=( -- "${named_args[@]}" )
	fi

	# Main Path | Invoke Make with generated Makefile and prepared arguments:
	make --makefile "${makefile}" "${make_args[@]}"

	# Main Path | Clean up temporary Makefile and exit with success:
	rm "${makefile}"
	exit 0
)

main "$@"
