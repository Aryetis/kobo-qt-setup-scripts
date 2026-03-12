#!/bin/bash
set -e

export CC=gcc-14
export CXX=g++-14

./koxtoolchain/gen-tc.sh kobo

chmod -R +rwx ${HOME}/x-tools
