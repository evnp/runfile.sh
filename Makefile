.PHONY: _tasks
_tasks: .tasks

.PHONY: start
start: stop # start app
	@run build env=dev # tasks can be run directly from other tasks
	@echo "starting app"

.PHONY: stop
stop: # stop app
	@echo "stopping app"

.PHONY: build
build: lint # build app for environment [vars: env]
	@[[ -n $(env) ]] && echo "buiding app for $(env)" || echo "error: missing env"

.PHONY: test
test: # run all tests or specific tests [vars: name1, name2, etc.]
	@run build env=test
	@[[ -n $(@) ]] && echo "running tests $(@)" || echo "running all tests"

.PHONY: lint
lint: # lint all files or specific file [vars: file]
	@[[ -n $(1) ]] && echo "linting file $(1)" || echo "linting all files"

.PHONY: .tasks
.tasks:
	@grep -E "^([a-zA-Z0-9 _-]+:[a-zA-Z0-9 _-]*#)" $(MAKEFILE_LIST) \
	| sed -Ee "s/^/  /" -e "s/[ ]*:[a-zA-Z0-9 _-]*#[ ]*/ · /"
