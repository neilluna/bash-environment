#!/usr/bin/env bash

script_version=2.0.0

script_name=$(basename ${BASH_SOURCE[0]})
script_dir=$(dirname ${BASH_SOURCE[0]})
script_path=${BASH_SOURCE[0]}

function echo_usage() {
	echo "${script_name} - Version ${script_version}"
	echo ""
	echo "Create a default .gitconfig file in the home directory."
	echo ""
	echo "Usage: ${script_name} [options] name email"
	echo ""
	echo "Options:"
	echo "      --help     Output this help information."
	echo "      --verbose  Verbose output."
	echo "  -v, --version  Output the version."
	echo ""
	echo "Arguments:"
	echo "  name   The name to set in the .gitconfig file."
	echo "  email  The email to set in the .gitconfig file."
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

# Echo an error message and exit.
# Usage: echo_error_and_exit message
function echo_error_and_exit()
{
	message=${1}
	echo_error "${message}"
	exit 1
}

# Argument variables with default values.
name=
email=
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
	if [ -z "${name}" ]; then
		name=${1}
	elif [ -z "${email}" ]; then
		email=${1}
	else
		while [ ${#} -gt 0 ]; do
			echo_error "${script_name}: Error: Invalid argument -- '${1}'" >&2
			shift
		done
		exit 1
	fi
	shift
done
if [ -z "${name}" ]; then
	echo_error "${script_name}: Error: Missing name parameter." >&2
	exit 1
fi
if [ -z "${email}" ]; then
	echo_error "${script_name}: Error: Missing email parameter." >&2
	exit 1
fi

[ ${verbose} == yes ] && echo_info "Setting git user.name to ${name} ..."
git config --global user.name "${name}" || exit 1
[ ${verbose} == yes ] && echo_info "Setting git user.email to ${email} ..."
git config --global user.email "${email}" || exit 1
[ ${verbose} == yes ] && echo_info "Setting git core.autocrlf to false ..."
git config --global --bool core.autocrlf false || exit 1
[ ${verbose} == yes ] && echo_info "Setting git core.filemode to false ..."
git config --global --bool core.filemode false || exit 1
[ ${verbose} == yes ] && echo_info "Setting git credential.helper to cache --timeout=3600 ..."
git config --global credential.helper "cache --timeout=3600" || exit 1
[ ${verbose} == yes ] && echo_info "Setting git push.default to simple ..."
git config --global push.default simple || exit 1

exit 0
