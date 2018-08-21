#!/bin/bash

#export SOONG_GEN_CMAKEFILES=1
#export SOONG_GEN_CMAKEFILES_DEBUG=1

# add some colors
WHITE='\033[1;37m'
GREEN='\033[0;32m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
NC='\033[0m'

_TARGETS=()
_CLEAN_TARGETS=()
_OPTIONS=()
_OUTPUT=$ANDROID_BUILD_TOP/out/development/compile_commands.json
_CLEAN=0
_SHOWCOMMANDS=""
_VERBOSE=0
_JSON2CMAKE=0

function conditionalprintf() {
	if [ "$1" == "1" ]; then
		printf "$2"
		return 0
	fi
	return 1
}

function printffail() {
	test $? -eq 0
	_PREVIOUS_FAILED="$?"
	conditionalprintf "$_PREVIOUS_FAILED" "$1"
	if [ $? -eq 0 ]; then
		exit 1
	fi
}

function printfverbose() {
	conditionalprintf "$_VERBOSE" "$1"
	return 0
}

function invokebear() {
	printf "${GREEN}>>> BuildEAR'ing${NC} ${PURPLE}'$@'${NC}\n"
	printfverbose "$ ${GREEN}bear --use-cc clang --use-c++ clang++ --append --cdb $_OUTPUT make ${PURPLE}$@${NC}\n"
	bear --use-cc clang --use-c++ clang++ --append --cdb $_OUTPUT make $@ $_SHOWCOMMANDS
	printffail "${RED}>>> BuildEAR of${NC} ${PURPLE}'$@'${NC} ${RED}failed${NC}\n"
}

function invokeclean() {
	printf "${GREEN}>>> Cleaning${NC} ${PURPLE}'$1'${NC}\n"
	printfverbose "$ ${GREEN}make ${PURPLE}$1${NC}\n"
	make clean-$1 $_SHOWCOMMANDS
	printffail "${RED}>>> Clean failed -- bad target${NC} ${PURPLE}'$1'${NC}\n"
}

_USAGE="${RED}>>> Usage:${NC}
Hooks to the build process and writes compilation-output file 'compile_commands.json'

SYNOPSIS:
  `basename $0` [ARGS] modules...

ARGS:
    --verbose     \tshow invoked commands
    --clean       \tinvoke 'make clean-MODULE' before invoking 'make MODULE'
    --json2cmake  \tgenerate 'CMakeLists.txt' in addition to 'compile_commands.json'
    --out FILENAME\tspecify a location of compilation-output instead of using default

Examples:
- Generate 'compile_commands.json' for 2 targets; clean before build:
    $ `basename $0` --clean --out ~/workspace/aosp/compile_commands.json surfaceflinger hwcomposer.ranchu
- Generate 'compile_commands.json' and 'CMakeLists.txt' for 'libgui':
    $ `basename $0` --json2cmake --out ~/workspace/aosp/compile_commands.json libgui
"

test $# -gt 0
printffail "$_USAGE"

while test $# -gt 0
do
    case "$1" in
	--verbose)
		_VERBOSE=1
		;;
	--clean)
		_CLEAN=1
		;;
	--json2cmake)
		_JSON2CMAKE=1
		;;
        --out)
		_OUTPUT="$2"
		shift
		;;
	--showcommands)
		_SHOWCOMMANDS="showcommands"
		;;
        *=*)
		printf "Found option ${PURPLE}'$1'${NC}\n"
		_OPTIONS+=("$1")
		;;
	--*)
		printf "${RED}Ignored bad option${NC} ${PURPLE}'$1'${NC}\n"
		;;
	*)
		_TARGETS+=("$1")
		_CLEAN_TARGETS+=("clean-$1")
		;;
    esac
    shift
done

if [ $_CLEAN -eq 1 ]; then
	invokeclean "${_OPTIONS[*]} ${_CLEAN_TARGETS[*]}"
fi

# build with compilation sniffing
invokebear "${_OPTIONS[*]} ${_TARGETS[*]}"

# insert newline
echo

if [ $_JSON2CMAKE -eq 1 ]; then
	printf "${GREEN}>>> Running json2cmake in${NC} `dirname $_OUTPUT`\n"
	cd `dirname $_OUTPUT`
	json2cmake -n $_OUTPUT
	printffail "${RED}>>> json2cmake failed -- have you installed it?${NC}\n"
	cd -
fi

printf "${GREEN}>>> Completede BuildEAR'ing of:${NC}\n"
printf "${PURPLE}- %s${NC}\n" "${_TARGETS[@]}"
printf "${GREEN}>>> Output:${NC} ${PURPLE}'$_OUTPUT'${NC}\n"
