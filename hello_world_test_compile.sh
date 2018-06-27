#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
echo Current path is: "$DIR"
export PATH=$PATH:"$DIR"/_install_dir_toolchains/bin
echo "$PATH"

# Compile for 64-bit window
LD_LIBRARY_PATH="$DIR"/_install_dir_toolchains/lib x86_64-w64-mingw32-gcc "$DIR"/hello_world_test.c -o "$DIR"/hello_world_test-w64.exe

