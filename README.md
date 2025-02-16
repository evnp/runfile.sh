runfile.sh
----------
```
      · Language-agnostic project task runner · Missing companion of the ubiquitous Make ·
      · Use a Runfile on its own to manage project tasks · start, build, test, lint, etc ·
      · Use Runfile & Makefile in tandem to keep project tasks and build steps organized ·
```

[![tests](https://github.com/evnp/runfile.sh/workflows/tests/badge.svg)](https://github.com/evnp/runfile.sh/actions)
[![shellcheck](https://github.com/evnp/runfile.sh/workflows/shellcheck/badge.svg)](https://github.com/evnp/runfile.sh/actions)
[![latest release](https://img.shields.io/github/release/evnp/runfile.sh.svg)](https://github.com/evnp/runfile.sh/releases/latest)
[![npm package](https://img.shields.io/npm/v/runfile.sh.svg)](https://www.npmjs.com/package/runfile.sh)
[![license](https://img.shields.io/badge/license-MIT-blue)](https://github.com/evnp/runfile.sh/blob/master/LICENSE.md)

**Contents** - [What?](https://github.com/evnp/runfile.sh#what) | [Usage](https://github.com/evnp/runfile.sh#usage) | [Install](https://github.com/evnp/runfile.sh#install) | [Tests](https://github.com/evnp/runfile.sh#tests) | [License](https://github.com/evnp/runfile.sh#license)

If you'd like to jump straight in, try one of these or go to the [Install](https://github.com/evnp/runfile.sh#install) section for more (curl, install man page, etc.):
```sh
brew tap evnp/runfile.sh && brew install runfile.sh
```
```sh
npm install -g runfile.sh
```

What is a Runfile?
------------------
A `Runfile` is like a `Makefile`, but simpler. Runfiles and Makefiles can live together within a project in harmony.

```make
# An example Runfile

start: build # start application, after building
  <command(s) to start application>

build: # build application
  <command(s) to build application>

test: build # run all tests, after building
  <command(s) to run all tests>
```

Where a Makefile might be used to codify steps which build various artefacts relevant to a project, a Runfile could be used to encode various tasks a person would often want to carry out when interacting with that project. For example: running tests, linting source code, installing dependencies, generating documentation, preparing a release. These tasks can be implemented within a Makefile, but using a Runfile make the process much simpler – Make is a powerful tool with file-change tracking and dependency-graph awareness, among many other things that aren't usually relevant to running simple tasks.

Runfiles can be thought of as filling a similar role to these other excellent projects: just, TODO

Usage
-----
```sh
$ run --runfile-help

· Usage · run ····················· Print list of all available tasks.
          run [options] [task] ···· Run a task (ignored if action is specified).
          run [options] [action] ·· Run a Runfile/Makefile action.

# ./Runfile syntax  (this is a comment!)
taskabc: # task description
  shell command(s) for task abc
taskxyz: taskabc # task description, taskxyz runs taskabc first just like Make would
  shell command(s) for task xyz
#^ whitespace doesn't matter; tabs, spaces, blank lines are all ok, or may be omitted

· Actions ·

-h --help --usage ····· Print this usage documentation then exit.
-v --version ·········· Print current runfile.sh version then exit.
--runfile ············· Print contents of nearest Runfile (in current dir or dir above).
--makefile ············ Print contents of Makefile generated from nearest Runfile.
--runfile-edit ········ Open nearest Runfile with \$EDITOR.
--makefile-edit ······· Open nearest Makefile with \$EDITOR.
--runfile-create ······ Write template Runfile in current dir.
--makefile-create ····· Write generated Makefile in current dir.
--runfile-overwrite ··· Overwrite existing Runfile with template Runfile.
--makefile-overwrite ·· Overwrite existing Makefile with generated Makefile.
--runfile-aliases ····· Print command aliases for nearest Runfile (for shell config).

· Options ·

--runfile-compact ···· Use "compact" formatting for Runfile when creating or printing.
--runfile-confirm ···· Always ask for confirmation before opening files with $EDITOR.
--runfile-noconfirm ·· Never ask for confirmation before opening files with $EDITOR.
--runfile-noedit ····· Never open files with $EDITOR.
--runfile-verbose ···· Print code line-by-line to terminal during task execution.
--makefile-compat ···· Disable all features not compatible with Make.

--make-dry-run ·· Don't execute task code, just print line-by-line to terminal instead.
--make-* ········ Pass any argument directly to they underlying Make command
                · by prefixing the intended Make argument with "--make-".
                · For example, --make-dry-run will pass --dry-run to Make.
```

Install
-------

Homebrew:
```sh
brew tap evnp/runfile.sh && brew install runfile.sh
```
NPM:
```sh
npm install -g runfile.sh
```
Curl:
```sh
read -rp $'\n'"Current directories in \$PATH:"$'\n'"$(echo $PATH|sed 's/:/\n/g'|sort)"$'\n\n'"Enter a directory from the list above: " && [[ -z "${REPLY}" ]] && echo "Cancelled (no directory entered)" || ( curl -L -o "${REPLY/\~/$HOME}/runfile.sh" https://github.com/evnp/runfile.sh/raw/main/runfile.sh && chmod +x "${REPLY/\~/$HOME}/runfile.sh" )
```
runfile.sh has no external dependencies, but it's good practice to audit code before downrunfile.sh onto your system to ensure it contains nothing unexpected. Please view the full source code for runfile.sh here: https://github.com/evnp/runfile.sh/blob/master/runfile.sh

If you also want to install runfile.sh's man page:
```sh
read -rp $'\n'"Current directories in \$(manpath):"$'\n'"$(manpath|sed 's/:/\n/g'|sort)"$'\n\n'"Enter a directory from the list above: " && [[ -z "${REPLY}" ]] && echo "Cancelled (no directory entered)" || curl -L -o "${REPLY/\~/$HOME}/man1/runfile.sh.1" https://github.com/evnp/runfile.sh/raw/main/man/runfile.sh.1
```
Verify installation:
```sh
runfile.sh -v
==> runfile.sh 2.0.2

brew test runfile.sh
==> Testing runfile.sh
==> /opt/homebrew/Cellar/runfile.sh/2.0.2/bin/runfile.sh test --print 1234 hello world
```

Tests
-------------
Run once:
```sh
npm install
npm test
```
Use `fswatch` to re-run tests on file changes:
```sh
brew install fswatch
npm install
npm run testw
```
Non-OSX: replace `brew install fswatch` with package manager of choice (see [fswatch docs](https://github.com/emcrisostomo/fswatch#getting-fswatch))
