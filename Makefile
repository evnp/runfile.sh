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
t test: # run all tests or specific test [vars: name='all']
	@[[ -n "$(name)" ]] && echo "run test $(name)" || echo "run test all"

.PHONY: r repl
r repl: # start shell in project environment [vars: env='']
	@echo "start shell in project environment: $(env)"

.PHONY: .tasks
.tasks:
	@grep -E "^[a-zA-Z0-9 _-]+:[a-zA-Z0-9 _-]*#" $(MAKEFILE_LIST) \
	| sed -Ee 's/^/\t/' -e "s/[ ]*:[a-zA-Z0-9 _-]*#[ ]*/ · /"
