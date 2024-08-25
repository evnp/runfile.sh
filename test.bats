#!/usr/bin/env bash

load './node_modules/bats-support/load'
load './node_modules/bats-assert/load'

function run() {
	local cmd
	cmd="${BATS_TEST_DESCRIPTION}"
	cmd="${cmd/${BATS_TEST_NUMBER} /}"
	cmd="${cmd/README /}"
	cmd="${cmd/run.sh/${BATS_TEST_DIRNAME}/run.sh}"
	if [[ "${cmd}" =~ ^([A-Z_]+=[^ ]*) ]]; then
		# handle env var declarations placed before test command
		export "${BASH_REMATCH[1]}"
		run ${cmd/${BASH_REMATCH[1]} /}
	else
		run ${cmd}
	fi
}

@test "${BATS_TEST_NUMBER} run.sh" {
	run
	assert_success
}
