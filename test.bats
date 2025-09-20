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
  start · start app
  stop · stop app
  build · build app for environment [vars: env]
  test · run all tests or specific tests [vars: name1, name2, etc.]
  lint · lint all files or specific file [vars: file]
EOF
)"

@test "${BATS_TEST_NUMBER} run" {
	execute_test_command
	assert_output -p "${task_list}"
	assert_success
}

function test_version() {
	execute_test_command
	assert_output --regexp "^[0-9]+\.[0-9]+\.[0-9]$"
	assert_success
}
@test "${BATS_TEST_NUMBER} run -v" { test_version; }
@test "${BATS_TEST_NUMBER} run --version" { test_version; }

function test_help() {
	execute_test_command
	assert_output -p "runfile.sh"
	assert_output --regexp "[0-9]+\.[0-9]+\.[0-9]"
	assert_output -p "Usage"
	assert_success
}
@test "${BATS_TEST_NUMBER} run --help" { test_help; }
@test "${BATS_TEST_NUMBER} run -h" { test_help; }

function test_runfile() {
	execute_test_command
	assert_output "$( cat ./Runfile )"
	assert_success
}
@test "${BATS_TEST_NUMBER} run --runfile" { test_runfile; }
@test "${BATS_TEST_NUMBER} run -r" { test_runfile; }

function test_runfile_compact() {
	execute_test_command
	assert_output "$( cat ./Runfile | sed -e '/^$/d' -e 's/^[[:space:]]//' )"
	assert_success
}
@test "${BATS_TEST_NUMBER} run --runfile --compact" { test_runfile_compact; }
@test "${BATS_TEST_NUMBER} run -r --compact" { test_runfile_compact; }

function test_makefile() {
	execute_test_command
	assert_output "$( cat ./Makefile )"
	assert_success
}
@test "${BATS_TEST_NUMBER} run --makefile" { test_makefile; }
@test "${BATS_TEST_NUMBER} run -m" { test_makefile; }

function test_makefile_task_start() {
	execute_test_command
	assert_output -p "$( cat ./Makefile | grep "@" | head -4 | sed 's/^.*@//' )"
	assert_success
}
@test "${BATS_TEST_NUMBER} run --makefile start" { test_makefile_task_start; }
@test "${BATS_TEST_NUMBER} run -m start" { test_makefile_task_start; }

function test_makefile_task_stop() {
	execute_test_command
	assert_output -p "$( cat ./Makefile | grep "@" | head -5 | tail -1 | sed 's/^.*@//' )"
	assert_success
}
@test "${BATS_TEST_NUMBER} run --makefile stop" { test_makefile_task_stop; }
@test "${BATS_TEST_NUMBER} run -m stop" { test_makefile_task_stop; }

@test "${BATS_TEST_NUMBER} run --alias" {
	execute_test_command
	assert_output "$( cat <<-EOF
		# Runfile Aliases
		alias rs='run start'
		alias rb='run build'
		alias rt='run test'
		alias rl='run lint'
		# END Runfile Aliases
	EOF
	)"
	assert_success
}
