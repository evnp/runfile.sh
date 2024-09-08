#!/usr/bin/env bash

load './node_modules/bats-support/load'
load './node_modules/bats-assert/load'

function execute_test_command() {
	local cmd
	cmd="${BATS_TEST_DESCRIPTION}"
	cmd="${cmd/${BATS_TEST_NUMBER} /}"
	cmd="${cmd/README /}"
	cmd="${cmd/run/${BATS_TEST_DIRNAME}/runfile.sh}"
	if [[ "${cmd}" =~ ^([A-Z_]+=[^ ]*) ]]; then
		# handle env var declarations placed before test command
		export "${BASH_REMATCH[1]}"
		run ${cmd/${BASH_REMATCH[1]} /}
	else
		run ${cmd}
	fi
}

task_list="$( cat <<EOF
	s start · start app
	stop · stop app
	b build · build app for environment [vars: env]
	t test · run all tests or specific tests [vars: name1, name2, etc.]
	l lint · lint all files or specific file [vars: file]
EOF
)"

@test "${BATS_TEST_NUMBER} run" {
	execute_test_command
	assert_output "${task_list}"
	assert_success
}

@test "${BATS_TEST_NUMBER} run --runfile-version" {
	execute_test_command
	assert_output --regexp "^[0-9]+\.[0-9]+\.[0-9]$"
	assert_success
}

@test "${BATS_TEST_NUMBER} run --runfile-help" {
	execute_test_command
	assert_output -p "runfile.sh"
	assert_output --regexp "[0-9]+\.[0-9]+\.[0-9]"
	assert_output -p "Usage"
	assert_output -p "Actions"
	assert_output -p "Options"
	assert_success
}

@test "${BATS_TEST_NUMBER} run --runfile" {
	execute_test_command
	assert_output "$( cat ./Runfile )"
	assert_success
}

@test "${BATS_TEST_NUMBER} run --runfile --runfile-compact" {
	execute_test_command
	assert_output "$( cat ./Runfile | sed -e '/^$/d' -e 's/^[[:space:]]//' )"
	assert_success
} # shortcut for above:
@test "${BATS_TEST_NUMBER} run --runfile-compact" {
	execute_test_command
	assert_output "$( cat ./Runfile | sed -e '/^$/d' -e 's/^[[:space:]]//' )"
	assert_success
}

@test "${BATS_TEST_NUMBER} run --makefile" {
	execute_test_command
	assert_output "$( cat ./Makefile )"
	assert_success
} # same as above; --runfile-compact should have no effect:
@test "${BATS_TEST_NUMBER} run --makefile --runfile-compact" {
	execute_test_command
	assert_output "$( cat ./Makefile )"
	assert_success
}

