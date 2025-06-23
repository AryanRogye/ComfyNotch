#!/bin/bash

# compile.sh
set -e

# Make sure build directory exists
mkdir -p build && cd build
cmake ..
make
