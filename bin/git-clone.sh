#!/usr/bin/env bash

script_version=2.0.0

script_name=$(basename ${BASH_SOURCE[0]})
script_dir=$(dirname ${BASH_SOURCE[0]})
script_path=${BASH_SOURCE[0]}

function echo_usage()
{
	echo "${script_name} - Version ${script_version}"
	echo ""
	echo "Clone a Git repository and set autocrlf and filemode to false."
	echo ""
	echo "Usage: ${script_name} [options] remote [local]"
	echo ""
	echo "Options:"
	echo "      --help     Output this help information."
	echo "      --verbose  Verbose output."
	echo "  -v, --version  Output the version."
	echo ""
	echo "Arguments:"
	echo "  remote  The remote repository URL."
	echo "  local   The local directory to clone into."
}

# ANSI color escape sequences for use in echo_color().
black='\e[30m'
red='\e[31m'
green='\e[32m'
yellow='\e[33m'
blue='\e[34m'
magenta='\e[35m'
cyan='\e[36m'
white='\e[37m'
reset='\e[0m'

# Echo color messages.
# Echoing ANSI escape codes for color works, yet tput does not.
# This may be caused by tput not being able to determine the terminal type.
# Usage: echo_color color message
function echo_color()
{
	color=${1}
	message=${2}
	echo -e "${color}${message}${reset}"
}

# Echo an informational message.
# Usage: echo_info message
function echo_info()
{
	message=${1}
	echo_color ${cyan} "${message}"
}

# Echo an error message.
# Usage: echo_error message
function echo_error()
{
	message=${1}
	echo_color ${red} "${message}"
}

# Echo an error message and exit.
# Usage: echo_error_and_exit message
function echo_error_and_exit()
{
	message=${1}
	echo_error "${message}"
	exit 1
}

# Argument variables with default values.
remote=
local=
verbose=no

# Parse the options using GNU getopt.
# On Mac OS X and FreeBSD, you have to install GNU getopt separately.
short_options="v"
long_options="help,verbose,version"
parsed_args=$(getopt -o ${short_options} -l ${long_options} -n ${script_name} -- "${@}")
return_code=${?}
if [ ${return_code} != 0 ]; then
	echo_error_and_exit "${script_name}: Error: getopt returned ${return_code}" >&2
fi

# Re-index positional arguments to match parsed structure.
# The quotes around "${parsed_args}" are necessary.
eval set -- "${parsed_args}"

# Parse the command line arguments.
while true; do
	case "${1}" in
		--help)
			echo_usage
			exit 0
			;;
		--verbose)
			verbose=yes
			shift
			;;
		-v | --version)
			echo "${script_version}"
			exit 0
			;;
		--)
			shift
			break
			;;
	esac
done
while [ ${#} -gt 0 ]; do
	if [ -z "${remote}" ]; then
		remote=${1}
	elif [ -z "${local}" ]; then
		local=${1}
	else
		while [ ${#} -gt 0 ]; do
			echo_error "${script_name}: Error: Invalid argument -- '${1}'" >&2
			shift
		done
		exit 1
	fi
	shift
done
if [ -z "${remote}" ]; then
	echo_error "${script_name}: Error: Missing remote parameter." >&2
	exit 1
fi
if [ -z "${local}" ]; then
	local=$(basename -s .git ${remote})
fi
if [ -d ${local} ]; then
	echo_error "${script_name}: Error: Directory '${local}' already exists." >&2
	exit 1
fi

# Clone the repo and change to its directory.
[ ${verbose} == yes ] && echo_color ${cyan} "Cloning ${remote} to ${local} ..."
git clone ${remote} ${local} || exit 1
cd ${local} || exit 1

# Fix autocrlf and filemode.
[ ${verbose} == yes ] && echo_color ${cyan} "Setting core.autocrlf to false ..."
git config core.autocrlf false || exit 1
[ ${verbose} == yes ] && echo_color ${cyan} "Setting core.filemode to false ..."
git config core.filemode false || exit 1

# Get the default branch name.
default_branch=$(git remote show origin | grep "HEAD branch" | awk '{print $3}')
[ ${verbose} == yes ] && echo_color ${cyan} "The default branch is '${default_branch}'"

exit 0
