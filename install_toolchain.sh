#!/bin/bash
set -e

./koxtoolchain/gen-tc.sh kobo

chmod -R +rwx ${HOME}/x-tools
