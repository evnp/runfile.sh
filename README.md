run.sh
----------
Minimalist project task runner built on the ubiquitous Make.

[![tests](https://github.com/evnp/run.sh/workflows/tests/badge.svg)](https://github.com/evnp/run.sh/actions)
[![shellcheck](https://github.com/evnp/run.sh/workflows/shellcheck/badge.svg)](https://github.com/evnp/run.sh/actions)
[![latest release](https://img.shields.io/github/release/evnp/run.sh.svg)](https://github.com/evnp/run.sh/releases/latest)
[![npm package](https://img.shields.io/npm/v/run.sh.svg)](https://www.npmjs.com/package/run.sh)
[![license](https://img.shields.io/github/license/evnp/run.sh.svg?color=blue)](https://github.com/evnp/run.sh/blob/master/LICENSE.md)

**Contents** - [Usage](https://github.com/evnp/run.sh#usage) | [Install](https://github.com/evnp/run.sh#install) | [Tests](https://github.com/evnp/run.sh#tests) | [License](https://github.com/evnp/run.sh#license)

If you'd like to jump straight to installing run.sh, please go to the [Install](https://github.com/evnp/run.sh#install) section or try one of these:
```sh
brew tap evnp/run.sh && brew install run.sh
# OR
npm install -g run.sh
# OR to curl directly, see https://github.com/evnp/run.sh#install
```

Usage
-----

🚧 Under construction 🚧

Install
-------

Homebrew:
```sh
brew tap evnp/run.sh && brew install run.sh
```
NPM:
```sh
npm install -g run.sh
```
curl:
```sh
read -rp $'\n'"Current \$PATH:"$'\n'"${PATH//:/ : }"$'\n\n'"Enter a directory from the list above: " \
  && curl -L -o "${REPLY/\~/$HOME}/run.sh" https://github.com/evnp/run.sh/raw/main/run.sh \
  && chmod +x "${REPLY/\~/$HOME}/run.sh"
```
run.sh has no external dependencies, but it's good practice to audit code before downrun.sh onto your system to ensure it contains nothing unexpected. Please view the full source code for run.sh here: https://github.com/evnp/run.sh/blob/master/run.sh

If you also want to install run.sh's man page:
```sh
read -rp $'\n'"Current \$MANPATH:"$'\n'"${MANPATH//:/ : }"$'\n\n'"Enter a directory from the list above: " \
  && curl -L -o "${REPLY/\~/$HOME}/man1/run.sh.1" https://github.com/evnp/run.sh/raw/main/man/run.sh.1
```
Verify installation:
```sh
run.sh -v
==> run.sh 2.0.2

brew test run.sh
==> Testing run.sh
==> /opt/homebrew/Cellar/run.sh/2.0.2/bin/run.sh test --print 1234 hello world
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

License
-------
MIT License

Copyright (c) 2024 Evan Campbell Purcer

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

