#!/usr/bin/env bash

# runfile.sh · v0.0.3

function version() {
	head -n 3 < "$0" | tail -1 | cut -c3-
}

function usage() {
cat <<EOF

· $( version ) ·

· Language-agnostic project task runner · Missing companion of the ubiquitous Make ·
· Use a Runfile on its own to manage project tasks · start, build, test, lint, etc ·
· Use Runfile & Makefile in tandem to keep project tasks and build steps organized ·

· Usage · run ····················· Print list of all available tasks.
          run [options] [task] ···· Run a task (ignored if action is specified).
          run [options] [action] ·· Run a Runfile/Makefile action.

# ./Runfile syntax  (this is a comment!)
taskabc: # task description
  shell command(s) for task abc
taskxyz: taskabc # task description, taskxyz runs taskabc first just like Make would
  shell command(s) for task xyz
#^ whitespace doesn't matter; tabs, spaces, blank lines are all ok, or may be omitted

· Actions ·

-h --help --usage ····· Print this usage documentation then exit.
-v --version ·········· Print current runfile.sh version then exit.
--runfile ············· Print contents of nearest Runfile (in current dir or dir above).
--makefile ············ Print contents of Makefile generated from nearest Runfile.
--makefile-task-TASK ·· Print contents of single task from nearest Makefile.
--runfile-edit ········ Open nearest Runfile with \$EDITOR.
--makefile-edit ······· Open nearest Makefile with \$EDITOR.
--runfile-create ······ Write template Runfile in current dir.
--makefile-create ····· Write generated Makefile in current dir.
--runfile-overwrite ··· Overwrite existing Runfile with template Runfile.
--makefile-overwrite ·· Overwrite existing Makefile with generated Makefile.
--runfile-aliases ····· Print command aliases for nearest Runfile (for shell config).
--runfile-aliases-write <filename> Attempt to write/update aliases in specified file.

· Options ·

--runfile-compact ···· Use "compact" formatting for Runfile when creating or printing.
--runfile-confirm ···· Always ask for confirmation before opening files with \$EDITOR.
--runfile-noconfirm ·· Never ask for confirmation before opening files with \$EDITOR.
--runfile-noedit ····· Never open files with \$EDITOR.
--runfile-verbose ···· Print code line-by-line to terminal during task execution.
--makefile-compat ···· Disable all features not compatible with Make.

--make-dry-run ······· Don't execute task code, just print line-by-line to terminal.
--make-ARGUMENT ······ Pass any argument directly to they underlying Make command
										 · by prefixing the intended Make argument with "--make-".
                		 · For example, --make-dry-run will pass --dry-run to Make.
EOF
}

function create-runfile() {
	if [[ " $* " != *' --runfile-overwrite '* ]] && [[ -e 'Runfile' ]]
	then
		echo 'Runfile already exists. To overwrite, use:'
		echo 'run --overwrite-runfile'
		exit 1
	fi

	if [[ " $* " != *' --makefile-compat '* ]]
	then
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
	else
optionally-compact-file "$@" <<EOF > Runfile
s start: stop # start app
	run build env=dev # tasks can be run directly from other tasks
	echo "starting app"

stop: # stop app
	echo "stopping app"

b build: lint # build app for environment [vars: env]
	[[ -n "\$(env)" ]] && echo "buiding app for \$(env)" || echo "error: missing env"

t test: # run all tests or specific test [vars: name]
	run build env=test
	[[ -n "\$(name)" ]] && echo "running tests \$(name)" || echo "running all tests"

l lint: # lint all files or specific file [vars: file]
	[[ -n "\$(file)" ]] && echo "linting file \$(file)" || echo "linting all files"
EOF
	fi
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

function print-runfile-commands() {
	# Print current Runfile commands:
	echo
	grep -E '[[:alnum:]_-][[:alnum:] _-]+:[[:alnum:] _-]*#' "$( smartcase-file runfile )" \
	| sed -Ee 's/:.*#/ · /g' -e 's/  / /g' -e 's/^/  /g'
	# Print Runfile command aliases if any are currently available:
	echo
	awk 'NR==FNR{a[$0]=1;next}a[$0]' <( bash -ic 'alias' ) <( print-runfile-aliases ) \
	| sed -e "s/\'/ /g" -e "s/= / · /" -e 's/^/  /' -e 's/$/\n/' \
	| perl -0777 -pe 's/\n\n(.)/\n\1/g'
}

function print-runfile-aliases() {
	echo '# Runfile Aliases'
	grep -E '[[:alnum:]_-][[:alnum:] _-]+:[[:alnum:] _-]*#' "$( smartcase-file runfile )" \
	| sed -E 's/.*(^| )([[:alnum:]_-][[:alnum:]_-]+):.*/\2/g' \
	| awk '!_[substr($1,1,1)]++' `# unique on first char of each command` \
	| sed -E "s/(.)(.*)/alias ${RUNFILE_ALIASES_PREFIX:-r}\1='run \1\2'/"
	echo '# END Runfile Aliases'
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

function wizard() {
	local state='action1' prev_states=() prev_runfiles=()

	if [[ -e 'Runfile' ]]
	then
		while TRUE
		do
			read -rsn1 -p ' · Runfile already exists. Overwrite? [y|N] · '
			if [[ "$REPLY" == 'y' || "$REPLY" == 'Y' ]]
			then
				rm Runfile
				echo
				break
			elif [[ "$REPLY" == 'n' || "$REPLY" == 'N' || "$REPLY" == '' ]]
			then
				exit 0
			else
				echo
			fi
		done
	fi

	read -rsn1 -p " · At each of the following prompts, press ENTER to continue · "
	echo

	read -rsn1 -p " · At each of the following prompts, type BACK to return to previous step · "
	echo

	while TRUE
	do
		if [[ -f 'Runfile' ]]
		then
			echo
			echo './Runfile'
			echo '---------'
			cat Runfile
			[[ "${state}" == 'description' ]] && echo
			echo '---------'
			echo "${prev_states[@]}"
			echo
		fi

		if [[ "${state}" == 'action1' || "${state}" == 'action2' ]]
		then
			if [[ "${state}" == 'action1' ]]
			then
				read -rp " · Enter first run action name, or type DONE ·"$'\n'" ··· "
			else
				read -rp " · Enter another run action name, or type DONE ·"$'\n'" ··· "
			fi
			if [[ "$REPLY" == 'BACK' ]]
			then
				if (( ${#prev_states[@]} )) && (( ${#prev_runfiles[@]} ))
				then
					echo "${prev_runfiles[0]}" > Runfile
					state="${prev_states[0]}"
					prev_states=( "${prev_states[@]:1}" )
					prev_runfiles=( "${prev_runfiles[@]:1}" )
				fi
			elif [[ "$REPLY" == 'DONE' ]]
			then
				break
			elif ! [[ "$REPLY" =~ ^[[:alnum:]_-]+$ ]]
			then
				echo " · Run command names should only have characters a-z A-Z 0-9 _ - and no spaces ·"
				echo " · Please try again ·"
				echo
			else
				prev_states=( "${state}" "${prev_states[@]}" )
				if [[ -f 'Runfile' ]]
				then
					prev_runfiles=( "$( cat Runfile )" "${prev_runfiles[@]}" )
				else
					prev_runfiles=( "" "${prev_runfiles[@]}" )
				fi
				echo -n "$REPLY:" >> Runfile
				state='description'
			fi
		elif [[ "${state}" == 'description' ]]
		then
			read -rp " · What does this action do? (leave blank to skip) ·"$'\n'" ··· "
			if [[ "$REPLY" == 'BACK' ]]
			then
				echo "PREV_STATES" "${prev_states[@]}"
				if (( ${#prev_states[@]} )) && (( ${#prev_runfiles[@]} ))
				then
					echo -n "${prev_runfiles[0]}" > Runfile
					state="${prev_states[0]}"
					prev_states=( "${prev_states[@]:1}" )
					prev_runfiles=( "${prev_runfiles[@]:1}" )
				fi
			else
				prev_states=( "${state}" "${prev_states[@]}" )
				prev_runfiles=( "$( cat Runfile )" "${prev_runfiles[@]}" )
				state='command1'
				if [[ -n "$REPLY" ]]
				then
					echo " # $REPLY" >> Runfile
				else
					echo >> Runfile
				fi
			fi
		elif [[ "${state}" == 'command1' ]]
		then
			read -rp " · Enter the first shell command that should be run ·"$'\n'" ··· "
			if [[ "$REPLY" == 'BACK' ]]
			then
				if (( ${#prev_states[@]} )) && (( ${#prev_runfiles[@]} ))
				then
					echo "${prev_runfiles[0]}" > Runfile
					state="${prev_states[0]}"
					prev_states=( "${prev_states[@]:1}" )
					prev_runfiles=( "${prev_runfiles[@]:1}" )
				fi
			elif [[ -n "$REPLY" ]]
			then
				prev_states=( "${state}" "${prev_states[@]}" )
				prev_runfiles=( "$( cat Runfile )" "${prev_runfiles[@]}" )
				state='command2'
				echo "  $REPLY" >> Runfile
			fi
		elif [[ "${state}" == 'command2' ]]
		then
			read -rp " · Enter another shell command that should be run, or type DONE ·"$'\n'" ·· "
			if [[ "$REPLY" == 'BACK' ]]
			then
				if (( ${#prev_states[@]} )) && (( ${#prev_runfiles[@]} ))
				then
					echo "${prev_runfiles[0]}" > Runfile
					state="${prev_states[0]}"
					prev_states=( "${prev_states[@]:1}" )
					prev_runfiles=( "${prev_runfiles[@]:1}" )
				fi
			elif [[ "$REPLY" == 'DONE' ]]
			then
				prev_states=( "${state}" "${prev_states[@]}" )
				state='action2'
			else
				prev_states=( "${state}" "${prev_states[@]}" )
				prev_runfiles=( "$( cat Runfile )" "${prev_runfiles[@]}" )
				echo "  $REPLY" >> Runfile
			fi
		fi
	done

	if [[ -f 'Runfile' ]]
	then
		echo
		echo "./Runfile"
		cat Runfile
		echo
		echo 'Your Runfile has been created successfully!'
		echo 'Type "run" to review available commands.'
		echo
	fi
}

function run() ( set -euo pipefail
	local makefile='' buffer='' at='' task=''
	local arg='' make_args=() named_args=() pos_args=() pos_arg_idx=0

	local task_re='' trap_re='' vbse_re_1='' vbse_re_2=''
	local trap_sig='' runfile_grep_filter_args=()

	[[ "$*" == '' ]] && print-runfile-commands && exit 0

	# -h, --help, --usage · Print usage documentation then exit.
	# -v, --version       · Print current runfile.sh version then exit.
	# -w, --wizard        · Take a guided process to create a runfile.
	# NOTE: Only handle these args if they are the ONLY args.
	# It should be possible to define runfile commands with their own -h, --help, etc.
	[[ "$*" == '-h' || "$*" == '--help' || "$*" == '--usage' ]] && usage && exit 0
	[[ "$*" == '-v' || "$*" == '--version' ]] && version | cut -dv -f2 && exit 0
	[[ "$*" == '-w' || "$*" == '--wizard' ]] && wizard && exit 0

	# --runfile-create    · Write template Runfile, then open in editor (optional).
	# --runfile-write     · Alias for --runfile-create.
	# --runfile-overwrite · Can be used to overwrite when Runfile already exists.
	[[ " $* " == *' --runfile-create '* ]] || \
	[[ " $* " == *' --runfile-write '* ]] || \
	[[ " $* " == *' --runfile-overwrite '* ]] && \
		create-runfile "$@" && edit-file-smartcase runfile --runfile-confirm "$@" && exit 0

	# --runfile-edit  · Edit current Runfile, or exit with error if not found.
	# --makefile-edit · Edit current Makefile, or exit with error if not found.
	[[ " $* " == *' --runfile-edit '* ]] && \
		cd-to-nearest-file runfile && edit-file-smartcase runfile "$@" && exit 0
	[[ " $* " == *' --makefile-edit '* ]] && \
		cd-to-nearest-file makefile && edit-file-smartcase makefile "$@" && exit 0

	# --runfile-aliases · Print current Runfile aliases, or exit with error if not found.
	[[ " $* " == *' --runfile-aliases '* ]] && \
		cd-to-nearest-file runfile && print-runfile-aliases "$@" && exit 0

	# TODO EXPERIMENTAL, file handling needs implementation:
	# --runfile-aliases-write
	[[ " $* " == *' --runfile-aliases-write '* ]] && \
		perl -0777 -pe "s/# Runfile Aliases\n.*# END Runfile Aliases\n/$(
			print-runfile-aliases "$@"
		)\n/" ~/.aliases && exit 0

	# --runfile · Print current Runfile, or exit with error if not found.
	[[ " $* " == *' --runfile '* ]] || \
	[[ "$*" == '--runfile-compact' ]] && \
		cd-to-nearest-file runfile && print-file-smartcase runfile "$@" && exit 0

	# --makefile-task-TASK · Print contents single task from nearest Makefile and exit.
	[[ " $* " =~ [[:space:]]--makefile-task-([[:alnum:]_-]+)[[:space:]] ]] && \
		RUNFILE_SKIP_SUBTASKS=1 run --make-dry-run "${BASH_REMATCH[1]}" && exit 0

	# If no Runfile in current dir, navigate up looking for one until we reach $HOME:
	cd-to-nearest-file runfile

	# Temporary Makefile which we will pass to make:
	makefile="$( mktemp )"

	# @-prefix causes Make to execute tasks silently (without printing task code):
	at="@"
	[[ " $* " == *' --runfile-verbose '* || " $* " == *' --make-dry-run '* ]] && \
		at="" # Remove @-prefix so that Make prints task code before executing tasks.

	# Separate arguments into categories:
	# make_args  · Arguments that will be passed on to Make.
	# named_args · name=value arguments interpolated into $(name) within task code.
	# pos_args   · Arguments interpolated into $(1) $(2) $(3) etc. within task code.
	#            · All positional args will be interpoated into $(@), space-separated.
	for arg in "$@"
	do
		if [[ "${arg}" == '--make-'* ]]
		then
			make_args+=( "${arg/make-}" )
		elif [[ "${arg}" =~ ^[[:alnum:]_-]+\= ]]
		then
			named_args+=( "${arg}" )
		elif [[ "${arg}" != '--runfile-'* && "${arg}" != '--makefile-'* ]]
		then
			if [[ -z "${task}" ]]
			then
				task="${arg}"
			else
				if [[ " $* " == *' --makefile-compat '* ]]
				then
					echo "Warning · Task '${task}' was run in Make-compatibility mode while being"
					echo "        · passed positional argument '${arg}' incompatible with Make."
					echo "        · Use a named argument instead ('run ${task} argname=${arg}') where"
					echo "        · argname corresponds with '\$(argname)' in '${task}' in Runfile."
					echo
				fi
				pos_args+=( "${arg}" )
			fi
		fi
	done

	# If --runfile-verbose specified, use modified patterns for Makefile .tasks list so
	# that when each task is printed, its commands are printed line-by-line underneath:
	if [[ " $* " == *' --runfile-verbose '* ]]
	then
		vbse_re_1='\\s+|'
		vbse_re_2='s/^([^[:space:]])/\\n\\1/g'
	fi

task_re='([[:alnum:]_-][[:alnum:][:space:]_-]+):([[:alnum:][:space:]_-]+)?#'
trap_re='^\s*(EXIT|HUP|INT|QUIT|ABRT|KILL|ALRM|TERM)'

if [[ "${RUNFILE_TRAP:-}" == '*' ]]
then
	runfile_grep_filter_args=( -E "^(${task_re}|${trap_re})" )
elif [[ -n "${RUNFILE_TRAP:-}" ]]
then
	runfile_grep_filter_args=( -E "^(${task_re}|\\s+${RUNFILE_TRAP})" )
else
	runfile_grep_filter_args=( -Ev "${trap_re}" )
fi

if [[ -n "${RUNFILE_SKIP_SUBTASKS:-}" ]]
then
	subtask_re=''
else
	subtask_re='\2'
fi

# ::::::::::::::::::::::::::::::::::::::::::
# Construct temporary Makefile from Runfile:
cat <<EOF> "${makefile}"
.PHONY: _tasks
_tasks: .tasks
$(
	grep "${runfile_grep_filter_args[@]}" < "$( smartcase-file runfile )" \
	| sed -E \
			-e 's/[[:space:]]*$//' \
				`# trim any trailing whitespace from lines` \
			-e "s!^[[:space:]]*([^[:space:]])!\t${at}\1!" \
				`# prefix every non-blank line with TAB (or TAB-@, if verbose)` \
			-e "s!^\t${at}${task_re}(.*)\$!\n.PHONY: \1\n\1:${subtask_re}\#\3!" \
				`# remove TAB (or TAB-@) prefix from lines that match task pattern` \
	| cat -s
)

.PHONY: .tasks
.tasks:
	@grep -E "^(${vbse_re_1}${task_re})" \$(MAKEFILE_LIST) \\
	| sed -Ee "${vbse_re_2:-s/^/  /}" -e 's/[[:space:]]*:[[:alnum:] _-]*#[[:space:]]*/ · /'
EOF
# Done with temporary Makefile construction.
# ::::::::::::::::::::::::::::::::::::::::::

	# Process interpolated args within generated Makefile: $(arg) $(@) $(1) $(2) etc.
	if [[ " $* " != *' --makefile-compat '* ]] && \
		# If running in Make compatibility mode, skip this section.
		[[ " $* " != *' --makefile '* ]] && \
		[[ " $* " != *' --makefile-create '* ]] && \
		[[ " $* " != *' --makefile-write '* ]] && \
		[[ " $* " != *' --makefile-overwrite '* ]]
		# If outputting Makefile, skip this section.
	then
		buffer="$(
			sed -E 's!(\$\((@|[0-9]+|[[:alpha:]][[:alnum:]_]*)\))!\`printf '"'%s' '\1'"'\`!g' \
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

	# --makefile-create    · Write generated Makefile, then open in editor (optional).
	# --makefile-write     · Alias for --makefile-create.
	# --makefile-overwrite · Can be used to overwrite when Makefile already exists.
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
				echo "Warning · Your runfile uses positional args \$(@) \$(1) \$(2) etc."
				echo "        · which aren't compatible with Make. You should update these"
				echo "        · commands to accept standard Make-style named arguments:"
				echo "        · \$(abc) in your Makefile, passed as: $ make task abc=xyz"
				echo
			fi
			print-makefile "${makefile}" > ./Makefile
			rm "${makefile}"
			edit-file-smartcase makefile --runfile-confirm
			exit 0
		fi
	fi

	# --makefile · Print generated Makefile then exit:
	if [[ " $* " == *' --makefile '* ]]
	then
		print-makefile "${makefile}"
		rm "${makefile}"
		exit 0
	fi

	# Main Path · Prepare arguments to be passed to Make, and set any specified traps:
	if [[ -n "${task}" ]]
	then
		make_args+=( "${task}" )

		# Set all traps specified by current task in Makefile:
		# (unless a RUNFILE_TRAP is currently being executed)
		if [[ -z "${RUNFILE_TRAP:-}" ]]
		then
			for trap_sig in $(
				RUNFILE_TRAP='*' run "--makefile-task-${task}" \
				| cut -d' ' -f1  | grep -vE '^make(\[\d+\])?\:' | xargs
			)
			do
				# shellcheck disable=SC2064
				# "Use single quotes, otherwise this expands now rather than when signalled."
				# We want this to expand now rather than when the trap is triggered.
				trap \
				"RUNFILE_SKIP_SUBTASKS=1 RUNFILE_TRAP=${trap_sig} run ${task} ${make_args[*]}" \
				"${trap_sig}"
			done
		elif [[ "${RUNFILE_TRAP}" != '*' ]]
		then
			# If a specific runfile trap is being triggered, remove that trap's prefix
			# (eg. EXIT) from lines in makefile so they can be executed normally:
			buffer="$( sed -E "s!^\t${at}${RUNFILE_TRAP} !\t${at}!" "${makefile}" )"

			# Write buffer back to temporary makefile:
			echo "${buffer}" > "${makefile}"
		fi
	fi
	if (( ${#named_args[@]} ))
	then
		make_args+=( -- "${named_args[@]}" )
	fi

	# Main Path · Invoke Make with generated Makefile and prepared arguments:
	make --makefile "${makefile}" "${make_args[@]}"

	# Main Path · Clean up temporary Makefile and exit with success:
	rm "${makefile}"
	exit 0
)

run "$@"
