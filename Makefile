.PHONY: _tasks
_tasks: .tasks

.PHONY: s start
s start: stop # start app
	@run build env=dev # tasks can be run directly from other tasks
	@echo "starting app"

.PHONY: stop
stop: # stop app
	@echo "stopping app"

.PHONY: b build
b build: lint # build app for environment [vars: env]
	@[[ -n $(env) ]] && echo "buiding app for $(env)" || echo "error: missing env"

.PHONY: t test
t test: build # run all tests or specific tests [vars: name]
	@[[ -n $(name) ]] && echo "running test $(name)" || echo "running all tests"

.PHONY: l lint
l lint: # lint all files or specific file [vars: file]
	@[[ -n $(file) ]] && echo "linting file $(file)" || echo "linting all files"

.PHONY: .tasks
.tasks:
	@grep -E "^[a-zA-Z0-9 _-]+:[a-zA-Z0-9 _-]*#" $(MAKEFILE_LIST) \
	| sed -Ee 's/^/\t/' -e "s/[ ]*:[a-zA-Z0-9 _-]*#[ ]*/ · /"
