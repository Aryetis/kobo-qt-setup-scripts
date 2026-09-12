#!/bin/bash
set -e

export GIT_TERMINAL_PROMPT=0

./koxtoolchain/gen-tc.sh kobo

chmod -R +rwx ${HOME}/x-tools
