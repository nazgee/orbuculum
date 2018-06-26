#!/bin/sh
# Touches everything 'native' in a given path

find $1 -type f \( -name "*.c" -o -name "*.cpp" -o -name "*.cc" -o -name "*.cxx" \) -exec touch {} +
