.PHONY: _tasks
_tasks: .tasks

.PHONY: start
start: stop # start app
	@run build env=dev # tasks can be run directly from other tasks
	@echo "starting app in 3 seconds"
	@loading
	@sleep 3

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
	@grep -E "^(([[:alnum:]_-][[:alnum:][:space:]_-]+):([[:alnum:][:space:]_-]+)?#)" $(MAKEFILE_LIST) \
	| sed -Ee "s/^/  /" -e 's/[[:space:]]*:[[:alnum:] _-]*#[[:space:]]*/ · /'
