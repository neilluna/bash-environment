#!/usr/bin/env bash

script_version=2.0.0

script_name=$(basename ${BASH_SOURCE[0]})
script_dir=$(dirname ${BASH_SOURCE[0]})
script_path=${BASH_SOURCE[0]}

function echo_usage()
{
	echo "${script_name} - Version ${script_version}"
	echo ""
	echo "Source the scripts in the ~/.bashrc.d directory."
	echo ""
	echo "Usage: source ${script_name}"
	echo ""
	echo "Options:"
	echo "      --help     Output this help information."
	echo "  -v, --version  Output the version."
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

# Echo an error message.
# Usage: echo_error message
function echo_error()
{
	message=${1}
	echo_color ${red} "${message}"
}

# Parse the options using GNU getopt.
# On Mac OS X and FreeBSD, you have to install GNU getopt separately.
short_options="v"
long_options="help,version"
parsed_args=$(getopt -o ${short_options} -l ${long_options} -n ${script_name} -- "${@}")
return_code=${?}
if [ ${return_code} != 0 ]; then
	echo_error "${script_name}: Error: getopt returned ${return_code}" >&2
	return 1
fi

# Re-index positional arguments to match parsed structure.
# The quotes around "${parsed_args}" are necessary.
eval set -- "${parsed_args}"

# Parse the command line arguments.
while true; do
	case "${1}" in
		--help)
			echo_usage
			return 0
			;;
		-v | --version)
			echo "${script_version}"
			return 0
			;;
		--)
			shift
			break
			;;
	esac
done
if [ ${#} -gt 0 ]; then
	while [ ${#} -gt 0 ]; do
		echo_error "${script_name}: Error: Invalid argument -- '${1}'" >&2
		shift
	done
	return 1
fi

for script in ~/.bashrc.d/*.sh; do
	source ${script}
done

return 0
