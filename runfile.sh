#!/usr/bin/env bash

# runfile.sh · v0.0.3

function bold() {
	echo "$( tput bold )$*$( tput sgr0 )"
}

function version() {
	head -n 3 < "$0" | tail -1 | cut -c3-
}

function usage() {
cat <<EOF

· $( version ) ·

· Language-agnostic project task runner · The venerable Make's missing companion ·
· Use Runfile by itself to manage your project tasks · start build test lint etc ·
· Use Runfile & Makefile in tandem to keep project tasks + build steps organized ·

· Usage · run ··················· Print list of all available tasks.
          run [task] ············ Run a task.
          run [task] [options] ·· Run a task with options available to task code.

          run --[help|version|runfile|makefile|edit|new|alias] [options]
          run -[h|v|r|m|e|n|a] ·· Actions for managing Runfiles; details below.

# ./Runfile -- syntax primer (this line is a comment!)
taskabc: # Task description.
  shell command(s) for task abc
taskxyz: taskabc # Task description, taskxyz runs taskabc first just like Make would.
  shell command(s) for task xyz
#^ Unlike Make, whitespace doesn't matter; tabs, spaces, extra blank lines are all ok.

-h --help ··········· Print this usage documentation then exit.
-v --version ········ Print current runfile.sh version then exit.
-r --runfile ········ Print contents of nearest Runfile (in current dir or dir above).
-m --makefile ······· Print contents of Makefile generated from nearest Runfile.
-m --makefile TASK ·· Print contents of single task from generated Makefile.
-e --edit ··········· Open nearest Runfile with \$EDITOR.
-n --new ············ Interactively create new Runfile in current dir.
-a --alias ·········· Show command aliases for nearest Runfile (for shell config).
-a --alias FILENAME · Attempt to write/update aliases within shell config file.
--eject ············· Generate Makefile from Runfile and write to current dir.

--verbose ··········· Print code line-by-line to terminal during task execution.
--compact ··········· Use "compact" formatting for Runfile when creating or printing.
--compat ············ Disable all features not compatible with Make.
--confirm ··········· Always ask for confirmation before opening files with \$EDITOR.
--noconfirm ········· Never ask for confirmation before opening files with \$EDITOR.
--noedit ············ Never open files with \$EDITOR.
RUNFILE_VERBOSE=1 RUNFILE_COMPACT=1   RUNFILE_COMPAT=1 ·  All options may also be  ·
RUNFILE_CONFIRM=1 RUNFILE_NOCONFIRM=1 RUNFILE_NOEDIT=1 · provided as env variables ·

--make-dry-run ······ Don't execute task code, just print line-by-line to terminal.
--make-ARGUMENT ····· Pass any argument directly to they underlying Make command
                    · by prefixing the intended Make argument with "--make-".
                    · For example, --make-dry-run will pass --dry-run to Make.
EOF
}

function new-from-template() {
	if [[ "$* " != '--new-from-template-overwrite '* ]] && [[ -e 'Runfile' ]]
	then
		echo 'Runfile already exists. To overwrite, use:'
		bold 'run --new-from-template-overwrite'
		echo
		exit 1
	fi

	if [[ " $* " != *' --compat '* ]] \
	&& ! [[ "${RUNFILE_COMPAT:-}" =~ ^(1|true|TRUE|True)$ ]]
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
	if [[ " $* " == *' --compact '* ]] \
	|| [[ "${RUNFILE_COMPACT:-}" =~ ^(1|true|TRUE|True)$ ]]
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
	if [[ " $* " != *' --noedit '* ]] \
	&& ! [[ "${RUNFILE_NOEDIT:-}" =~ ^(1|true|TRUE|True)$ ]]
	then
		[[ " $* " == *' --confirm '* || "${RUNFILE_CONFIRM:-}" =~ ^(1|true|TRUE|True)$ ]] && \
		[[ " $* " != *' --noconfirm '* ]] && \
		! [[ "${RUNFILE_NOCONFIRM:-}" =~ ^(1|true|TRUE|True)$ ]] && \
			read -rsn1 -p "$( bold 'Press any key' ) to edit $( bold "${name}" ) with $( bold "$EDITOR" ) · CTRL+C to exit "
		$EDITOR "${name}"
	fi
}

function print-file-smartcase() {
	optionally-compact-file "$@" < "$( smartcase-file "$1" )"
}

function print-makefile() {
	sed -E "s!\tmake --makefile ${makefile} !\tmake !" "$@"
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
			echo "run --new"
			# Note: This message pertains to the user's shell which _won't_ have
			# changed directory, because this script's main function uses a subshell.
			# So there's no need to change directory back to where we started here.
			exit 1
		fi
	done
}

function ordinal() {
	case "$1" in
		*1[0-9] | *[04-9]) echo "$1"th ;;
		*1) echo "$1"st ;;
		*2) echo "$1"nd ;;
		*3) echo "$1"rd ;;
	esac
}

function wizard() {
	local state='task1' task='' taskidx=0 cmdidx=0 prev_states=() prev_runfiles=()

	if [[ -e 'Runfile' ]]
	then
		while TRUE
		do
			read -rsn1 -p " ·  Runfile already exists. $( bold 'Overwrite?' )  ·  [ $( bold 'y' ) | $( bold 'N' ) ]  · "
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

	function record-step() {
		prev_states=( "${state}" "${prev_states[@]}" )
		prev_tasks=( "${task}" "${prev_tasks[@]}" )
		prev_taskidxs=( "${taskidx}" "${prev_taskidxs[@]}" )
		prev_cmdidxs=( "${cmdidx}" "${prev_cmdidxs[@]}" )
		if [[ -f 'Runfile' ]]
		then
			prev_runfiles=( "$( cat Runfile )" "${prev_runfiles[@]}" )
		else
			prev_runfiles=( "" "${prev_runfiles[@]}" )
		fi
	}

	function undo-step() {
		cat <<-EOF > Runfile
			${prev_runfiles[0]}
		EOF
		state="${prev_states[0]}"
		task="${prev_tasks[0]}"
		taskidx="${prev_taskidxs[0]}"
		cmdidx="${prev_cmdidxs[0]}"
		prev_states=( "${prev_states[@]:1}" )
		prev_runfiles=( "${prev_runfiles[@]:1}" )
		prev_tasks=( "${prev_tasks[@]:1}" )
		prev_taskidxs=( "${prev_taskidxs[@]:1}" )
		prev_cmdidxs=( "${prev_cmdidxs[@]:1}" )
	}

	while TRUE
	do
		if [[ -f 'Runfile' ]]
		then
			echo
			echo './Runfile'
			echo -n '┌────┴'
			printf "─%.0s" $( seq $(( "$( awk '{ print length }' Runfile | sort -n | tail -1 )" - 8 )))
			echo '─┐'
			echo
			bold "$( sed "s/#.*$/$( tput sgr0 )&$( tput bold )/" Runfile )"
			echo
			echo -n '└─────'
			printf "─%.0s" $( seq $(( "$( awk '{ print length }' Runfile | sort -n | tail -1 )" - 8 )))
			echo '─┘'
			echo
		fi

		if [[ "${state}" == 'finish' ]]
		then
			echo 'Your Runfile has been created successfully!'
			echo "Start using it by typing $( bold 'run' ) to review available commands."
			echo
			break
		elif [[ "${state}" == 'task1' || "${state}" == 'task2' ]]
		then
			if [[ -z "${task}" ]]
			then
				read -rp " ·  Enter $( bold "$( ordinal "$(( taskidx + 1 ))" )" ) task…  ·  [ $( bold 'leave blank' ) to edit template Runfile in $( bold "$EDITOR" ) instead ]  ·"$'\n'"$( bold ' ·· ' )"
			else
				read -rp " ·  Enter $( bold "$( ordinal "$(( taskidx + 1 ))" )" ) task…  ·  [ $( bold 'leave blank' ) to continue | $( bold 'UNDO' ) to go back ]  ·"$'\n'"$( bold ' ·· ' )"
			fi
			if [[ "$REPLY" == 'UNDO' ]]
			then
				if (( ${#prev_states[@]} )) && (( ${#prev_runfiles[@]} ))
				then
					undo-step
				fi
			elif [[ "$REPLY" == '' && -z "${task}" ]]
			then
				new-from-template "$@" && edit-file-smartcase runfile "$@" && exit 0
			elif [[ "$REPLY" == '' ]]
			then
				state="finish"
			elif ! [[ "$REPLY" =~ ^[[:alnum:]_-]+$ ]]
			then
				if [[ -n "$REPLY" ]]
				then
					echo " ·  Run command names should only have characters a-z A-Z 0-9 _ - and no spaces  · "
					echo " ·  $( bold 'Please try again' )  · "
					echo
				fi
			else
				record-step

				if grep -q '[^[:space:]]' Runfile &>/dev/null
				then
					echo -n "$REPLY:" >> Runfile
				else
					echo -n "$REPLY:" > Runfile
				fi

				state='description'
				task="$REPLY"
				(( taskidx++ ))
				cmdidx=0
			fi
		elif [[ "${state}" == 'description' ]]
		then
			read -rp " ·  What does $( bold "${task}" ) do?  ·  [ $( bold 'leave blank' ) to skip | $( bold 'UNDO' ) to go back ]  ·"$'\n'"$( bold ' ·· ' )"
			if [[ "$REPLY" == 'UNDO' ]]
			then
				if (( ${#prev_states[@]} )) && (( ${#prev_runfiles[@]} ))
				then
					undo-step
				fi
			else
				record-step

				if [[ -n "$REPLY" ]]
				then
					# Append to last line of file:
					sed '$s/$/'" # $REPLY"'/' <<-EOF > Runfile
						${prev_runfiles[0]}
					EOF
				else
					# Append newline to file:
					echo >> Runfile
				fi

				state='command1'
			fi
		elif [[ "${state}" == 'command1' ]]
		then
			read -rp " ·  Enter $( bold '1st' ) command for $( bold "${task}" )…  ·"$'\n'"$( bold ' ·· ' )"
			if [[ "$REPLY" == 'UNDO' ]]
			then
				if (( ${#prev_states[@]} )) && (( ${#prev_runfiles[@]} ))
				then
					undo-step
				fi
			elif [[ -n "$REPLY" ]]
			then
				record-step

				echo "  $REPLY" >> Runfile

				state='command2'
				(( cmdidx++ ))
			fi
		elif [[ "${state}" == 'command2' ]]
		then
			read -rp " ·  Enter $( bold "$( ordinal "$(( cmdidx + 1 ))" )" ) command for $( bold "${task}" )…  ·  [ $( bold 'leave blank' ) to continue | $( bold 'UNDO' ) to go back ]  ·"$'\n'"$( bold ' ·· ' )"
			if [[ "$REPLY" == 'UNDO' ]]
			then
				if (( ${#prev_states[@]} )) && (( ${#prev_runfiles[@]} ))
				then
					undo-step
				fi
			elif [[ "$REPLY" == '' ]]
			then
				record-step

				state='task2'
			else
				record-step

				echo "  $REPLY" >> Runfile

				(( cmdidx++ ))
			fi
		fi
	done
}

function run() ( set -euo pipefail
	local makefile='' buffer='' task=''
	local arg='' make_args=() named_args=() pos_args=() pos_arg_idx=0

	local runfile_variables='' runfile_variable_re=''
	local task_re='' trap_re='' vbse_re_1='' vbse_re_2=''
	local trap_sig='' runfile_grep_filter_args=()

	[[ "$*" == '' ]] && print-runfile-commands && exit 0

	for action in help version runfile makefile edit new alias eject v r m e n a e
	do
		if (( ${#action} == 1 ))
		then
			action="-${action}"
		else
			action="--${action}"
		fi
		if [[ "$* " =~ ^((-[a-z]|--[a-z][a-z-]+)[[:space:]])+${action}[[:space:]] ]]
		then
			echo "error: $( bold "${action}" ) should be first argument"
			if ! [[ "${action}" =~ ^(-m|--makefile|-a|--alias)$ ]]
			then
				echo "hint: $( bold "run ${action} ${*//${action}/}" )"
			fi
			exit 1
		fi
	done

	# -h, --help, --usage · Print usage documentation then exit.
	# -v, --version       · Print current runfile.sh version then exit.
	# -n, --new           · Interactively create a runfile.
	# -e, --edit          · Edit nearest Runfile, or exit with error if not found.
	[[ "$* " == '-h '* || "$* " == '--help '* ]] && usage && exit 0
	[[ "$* " == '-v '* || "$* " == '--version '* ]] && version | cut -dv -f2 && exit 0
	[[ "$* " == '-n '* || "$* " == '--new '* ]] && wizard "$@" && exit 0
	[[ "$* " == '-e '* || "$* " == '--edit '* ]] && \
		cd-to-nearest-file runfile && edit-file-smartcase runfile "$@" && exit 0

	# --new-from-template · Create Runfile from template, then open in editor (optional).
	[[ "$* " == '--new-from-template '* ]] && \
		new-from-template "$@" && edit-file-smartcase runfile --confirm "$@" && exit 0

	# -a, --alias · Print current Runfile aliases, or exit with error if not found.
	[[ "$* " == '-a '* || "$* " == '--alias '* ]] && \
		cd-to-nearest-file runfile && print-runfile-aliases "$@" && exit 0
	# TODO EXPERIMENTAL, file handling needs implementation:
	# -a, --alias FILENAME · Attempt to write/update aliases within shell config file.
	[[ "$*" =~ ^(-a|--alias)[=[:space:]]([^[:space:]]+) ]] && \
		perl -0777 -pe "s/# Runfile Aliases\n.*# END Runfile Aliases\n/$(
			print-runfile-aliases "$@"
		)\n/" "${BASH_REMATCH[2]}" && exit 0

	# --runfile · Print current Runfile, or exit with error if not found.
	[[ "$* " == '-r '* || "$* " == '--runfile '* ]] && \
		cd-to-nearest-file runfile && print-file-smartcase runfile "$@" && exit 0

	# --makefile TASK · Print contents single task from nearest Makefile and exit.
	[[ "$*" =~ ^(-m|--makefile)[=[:space:]]([^[:space:]]+) ]] && \
		RUNFILE_SKIP_SUBTASKS=1 run --make-dry-run "${BASH_REMATCH[2]}" && exit 0

	# If no Runfile in current dir, navigate up looking for one until we reach $HOME:
	cd-to-nearest-file runfile

	# Temporary Makefile which we will pass to make:
	makefile="$( mktemp )"

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
		else
			if [[ -z "${task}" ]]
			then
				task="${arg}"
			else
				if [[ " $* " == *' --compat '* ]] \
				|| [[ "${RUNFILE_COMPAT:-}" =~ ^(1|true|TRUE|True)$ ]]
				then
					echo "$( bold 'Warning' ) · Task $( bold "${task}" ) was run in Make-compatibility mode while being"
					echo "        · passed positional argument $( bold "${arg}" ) incompatible with Make."
					echo "        · Use a named argument instead ($( bold "run ${task} argname=${arg}" )) where"
					echo "        · argname corresponds with $( bold "\$(argname)" ) in $( bold "${task}" ) in Runfile."
					echo
				fi
				pos_args+=( "${arg}" )
			fi
		fi
	done

	# If --verbose specified, use modified patterns for Makefile .tasks list so
	# that when each task is printed, its commands are printed line-by-line underneath:
	if [[ " $* " == *' --verbose '* ]] \
	|| [[ "${RUNFILE_VERBOSE:-}" =~ ^(1|true|TRUE|True)$ ]]
	then
		vbse_re_1='\\s+|'
		vbse_re_2='s/^([^[:space:]])/\\n\\1/g'
	fi

	task_re='([[:alnum:]_-][[:alnum:][:space:]_-]+):([[:alnum:][:space:]_-]+)?#'
	trap_re='(EXIT|HUP|INT|QUIT|ABRT|KILL|ALRM|TERM)'

	if [[ "${RUNFILE_TRAP:-}" == '*' ]]
	then
		runfile_grep_filter_args=( -E "^(${task_re}|\\s*${trap_re})" )
	elif [[ -n "${RUNFILE_TRAP:-}" ]]
	then
		runfile_grep_filter_args=( -E "^(${task_re}|\\s+${RUNFILE_TRAP})" )
	else
		runfile_grep_filter_args=( -Ev "^\s*${trap_re}" )
	fi

	if [[ -n "${RUNFILE_SKIP_SUBTASKS:-}" ]]
	then
		subtask_re=''
	else
		subtask_re='\2'
	fi

	runfile_variable_re="^[[:space:]]*[A-Z]+ :*= "
	runfile_variables="$( \
		grep -E "${runfile_variable_re}" "$( smartcase-file runfile )" || true
	)"
	if [[ -n "${runfile_variables}" ]]
	then
		runfile_variables="${runfile_variables}"$'\n\n'
	fi

# ::::::::::::::::::::::::::::::::::::::::::
# Construct temporary Makefile from Runfile:
# Note: <<-EOF doesn't produce correct indentation for final lines; <<EOF required.
cat <<EOF> "${makefile}"
${runfile_variables}.PHONY: _tasks
_tasks: .tasks
$(
	grep "${runfile_grep_filter_args[@]}" "$( smartcase-file runfile )" \
	| grep -Ev "${runfile_variable_re}" \
	| sed -E \
			-e 's/[[:space:]]*$//' \
				`# trim any trailing whitespace from lines` \
			-e "s!^[[:space:]]*([^[:space:]])!\t\1!" \
				`# prefix every non-blank line with TAB` \
			-e "s!^\t${task_re}(.*)\$!\n.PHONY: \1\n\1:${subtask_re}\#\3!" \
				`# remove TAB prefix from lines that match task pattern` \
			-e "s!^\t(if|elif|then|else|for|while)[[:space:]](.*;.*)\$!\t\1 \2 \\\\!" \
			-e "s!^\t(if|elif|then|else|for|while)[[:space:]]([^;]*)\$!\t\1 \2; \\\\!" \
			-e "s!^\t(then|do|else|elif)\$!\t\1 \\\\!" \
				`# automatically add backslashes to multiline statements (if, for, while)` \
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
	if [[ " $* " != *' --compat '* ]] && \
		! [[ "${RUNFILE_COMPAT:-}" =~ ^(1|true|TRUE|True)$ ]] && \
		# If running in Make compatibility mode, skip this section.
		[[ " $* " != *' --makefile '* && " $* " != *' -m '* ]] && \
		[[ " $* " != *' --eject '* ]]
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

	# --eject · Write generated Makefile, then open in editor (optional).
	if [[ "$* " == '--eject '* || "$* " == '--eject-overwrite '* ]]
	then
		if [[ "$* " != '--eject-overwrite '* ]] \
		&& [[ -e 'Makefile' && ! -d 'Makefile' ]]
		then
			echo 'Makefile already exists. To overwrite, use:'
			bold 'run --eject-overwrite'
			echo
			rm "${makefile}"
			exit 1
		else
			if grep -qE '\$\([@0-9]\)' "${makefile}"
			then
				echo "$( bold 'Warning' ) · Your runfile uses positional args $( bold "\$(@) \$(1) \$(2)" ) etc."
				echo "        · which aren't compatible with Make. You should update these"
				echo "        · commands to accept standard Make-style named arguments:"
				echo "        · $( bold "\$(abc)" ) in your Makefile, passed as: $( bold 'make task abc=xyz' )"
				echo
			fi
			print-makefile "${makefile}" > ./Makefile
			rm "${makefile}"
			edit-file-smartcase makefile --confirm
			exit 0
		fi
	fi

	# --makefile · Print generated Makefile then exit:
	if [[ "$* " == '-m '* || "$* " == '--makefile '* ]]
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
				RUNFILE_TRAP='*' run --makefile "${task}" \
				| cut -d' ' -f1  | grep -vE '^make(\[\d+\])?\:' | xargs
			)
			do
				# First ensure trap_sig is valid:
				if [[ "${trap_sig}" =~ ^${trap_re}$ ]]
				then
					# shellcheck disable=SC2064
					# "Use single quotes, otherwise this expands now rather than when signalled."
					# We want this to expand now rather than when the trap is triggered.
					trap \
					"RUNFILE_SKIP_SUBTASKS=1 RUNFILE_TRAP=${trap_sig} run ${task} ${make_args[*]}" \
					"${trap_sig}"
				fi
			done
		elif [[ "${RUNFILE_TRAP}" != '*' ]]
		then
			# If a specific runfile trap is being triggered, remove that trap's prefix
			# (eg. EXIT) from lines in makefile so they can be executed normally:
			buffer="$( sed -E "s!^\t${RUNFILE_TRAP} !\t!" "${makefile}" )"

			# Write buffer back to temporary makefile:
			echo "${buffer}" > "${makefile}"
		fi
	fi
	if (( ${#named_args[@]} ))
	then
		make_args+=( -- "${named_args[@]}" )
	fi

	# Main Path · Invoke Make with generated Makefile and prepared arguments:
	if [[ " $* " == *' --verbose '* ]] \
	|| [[ "${RUNFILE_VERBOSE:-}" =~ ^(1|true|TRUE|True)$ ]] \
	|| [[ " $* " == *' --make-dry-run '* ]]
	then
		make --makefile "${makefile}" "${make_args[@]}"
	else
		make --silent --makefile "${makefile}" "${make_args[@]}"
	fi

	# Main Path · Clean up temporary Makefile and exit with success:
	rm "${makefile}"
	exit 0
)

run "$@"
