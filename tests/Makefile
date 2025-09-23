SHELL = bash

.PHONY: _tasks
_tasks: .tasks

.PHONY: start
start: stop # start app
	run build env=dev # tasks can be run directly from other tasks
	echo "starting app in 3 seconds"
	loading
	sleep 3

.PHONY: stop
stop: # stop app
	echo "stopping app"

.PHONY: build
build: lint # build app for environment [vars: env]
	[[ -n $(env) ]] && echo "buiding app for $(env)" || echo "error: missing env"

.PHONY: test
test: # run all tests or specific tests [vars: name1, name2, etc.]
	run build env=test
	[[ -n $(@) ]] && echo "running tests $(@)" || echo "running all tests"

.PHONY: lint
lint: # lint all files or specific file [vars: file]
	[[ -n $(1) ]] && echo "linting file $(1)" || echo "linting all files"

.PHONY: complex
complex: # a sample command exploring complex multiline syntax
	echo "--- for loops ---"

	for x in abc hjkl xyz; \
	do \
		echo -n "$${x} :: "; \
	done
	echo

	for x in abc hjkl xyz; do \
		echo -n "$${x} :: "; \
	done
	echo

	for x in abc hjkl xyz; \
	do echo -n "$${x} :: "; \
	done
	echo

	echo "--- while loops ---"

	while read x; \
	do \
		echo -n "$${x} :: "; \
	done <<< $$'abc\n hjkl\n xyz'
	echo

	while read x; do \
		echo -n "$${x} :: "; \
	done <<< $$'abc\n hjkl\n xyz'
	echo

	while read x; \
	do echo -n "$${x} :: "; \
	done <<< $$'abc\n hjkl\n xyz'
	echo

	echo "--- if constructs ---"

	x=''
	if [[ -z "$${x}" ]]; \
	then \
		echo -n "abc"; \
		echo -n " :: "; \
	elif [[ "$${x}" =~ a[Bb][a-z]$$ ]]; \
	then \
		echo -n "hjkl"; \
		echo -n " :: "; \
	else \
		echo -n "xyz"; \
		echo -n " :: "; \
	fi

	y=''
	if [[ -n "$${y}" ]]; then \
		echo -n "abc"; \
		echo -n " :: "; \
	elif ! [[ "$${y}" =~ a[Bb][a-z]$$ ]]; then \
		echo -n "hjkl"; \
		echo -n " :: "; \
	else \
		echo -n "xyz"; \
		echo -n " :: "; \
	fi

	z=''
	if [[ -z "$${x}" ]]; \
	then x='abc'; echo -n "$${x} :: "; \
	elif [[ x =~ a[Bb][a-z]$$ ]]; \
	then x='hjkl'; echo -n "$${x} :: "; \
	else echo -n "$${x} :: "; \
	fi
	echo

	echo "--- for loops :: pathological semicolon usage ---"

	for x in abc hjkl xyz; \
	do \
		echo -n "$${x} :: "; \
	done
	echo

	for x in abc hjkl xyz; do \
		echo -n "$${x} :: "; \
	done
	echo

	for x in abc hjkl xyz; \
	do echo -n "$${x} :: "; \
	done
	echo

	echo "--- while loops :: pathological semicolon usage ---"

	while read x; \
	do \
		echo -n "$${x} :: "; \
	done <<< $$'abc\n hjkl\n xyz';
	echo

	while read x; do \
		echo -n "$${x} :: "; \
	done <<< $$'abc\n hjkl\n xyz';
	echo

	while read x; \
	do echo -n "$${x} :: "; \
	done <<< $$'abc\n hjkl\n xyz';
	echo

	echo "--- if constructs :: pathological semicolon usage ---"

	x=''
	if [[ -z "$${x}" ]]; \
	then \
		echo -n "abc"; \
		echo -n " :: "; \
	elif [[ "$${x}" =~ a[Bb][a-z]$$ ]]; \
	then \
		echo -n "hjkl"; \
		echo -n " :: "; \
	else \
		echo -n "xyz"; \
		echo -n " :: "; \
	fi

	y=''
	if [[ -n "$${y}" ]]; then \
		echo -n "abc"; \
		echo -n " :: "; \
	elif ! [[ "$${y}" =~ a[Bb][a-z]$$ ]]; then \
		echo -n "hjkl"; \
		echo -n " :: "; \
	else \
		echo -n "xyz"; \
		echo -n " :: "; \
	fi

	z=''
	if [[ -z "$${x}" ]]; \
	then x='abc'; echo -n "$${x} :: "; \
	elif [[ x =~ a[Bb][a-z]$$ ]]; \
	then x='hjkl'; echo -n "$${x} :: "; \
	else echo -n "$${x} :: "; \
	fi

.PHONY: .tasks
.tasks:
	@grep -E "^(([[:alnum:]_-][[:alnum:][:space:]_-]+):([[:alnum:][:space:]_-]+)?#)" $(MAKEFILE_LIST) \
	| sed -Ee "s/^/  /" -e 's/[[:space:]]*:[[:alnum:] _-]*#[[:space:]]*/ · /'
