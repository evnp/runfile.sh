.PHONY: _tasks
_tasks: .tasks

.PHONY: s start
s start: end # start app
	@echo "start app"
	@make frontend

.PHONY: e end
e end: # stop app
	@echo "stop app"

.PHONY: t test
t test: # run all tests or specific test [vars: name]
	@[[ -n $(1) ]] && echo "run test $(1)" || echo "run test all"

.PHONY: tests
tests: # run multiple tests [vars: name1, name2, etc.]
	@echo "run tests $(@)"

.PHONY: r repl
r repl: # start shell in project environment [vars: env='']
	@echo "start shell in project environment: $(env)"

.PHONY: .tasks
.tasks:
	@grep -E "^[a-zA-Z0-9 _-]+:[a-zA-Z0-9 _-]*#" $(MAKEFILE_LIST) \
	| sed -Ee 's/^/\t/' -e "s/[ ]*:[a-zA-Z0-9 _-]*#[ ]*/ · /"
