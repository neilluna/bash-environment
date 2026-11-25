#!/usr/bin/env bash

script_version=2.0.0

script_name=$(basename ${BASH_SOURCE[0]})
script_dir=$(dirname ${BASH_SOURCE[0]})
script_path=${BASH_SOURCE[0]}

function echo_usage() {
	echo "${script_name} - Version ${script_version}"
	echo ""
	echo "Create an SSH private and public key pair. The keys will be placed in the"
	echo "current directory, and named the same as the key comment."
	echo ""
	echo "Usage: ${script_name}: [options]"
	echo ""
	echo "Options:"
	echo "      --help     Output this help information."
	echo "  -h, --host     Specify the host name."
	echo "  -u, --user     Specify the user name."
	echo "      --verbose  Verbose output."
	echo "  -v, --version  Output the version."
	echo ""
	echo "Note:"
	echo "  The key comment and key file basename will be created as follows:"
	echo "    id_rsa_user_host_yymmdd"
	echo "  where yymmdd is the current date."
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
user=${USER}
host=$(hostname)
verbose=no

# Parse the options using GNU getopt.
# On Mac OS X and FreeBSD, you have to install GNU getopt separately.
short_options="h:u:v"
long_options="help,host:,user:,verbose,version"
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
		-h | --host)
			host=${2}
			shift 2
			;;
		-u | --user)
			user=${2}
			shift 2
			;;
		--verbose)
			verbose=yes
			shift
			;;
		-v | --version)
			echo "${script_name} - Version ${script_version}"
			exit 0
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
	exit 1
fi

comment=id_rsa_${user}_${host}_$(date +%Y%m%d)
key_file=${comment}

[ ${verbose} == yes ] && echo_info "The key comment will be ${comment}"

if [ -f ${key_file} ]; then
	echo_error_and_exit "${script_name}: Error: ${key_file} already exists."
fi

if [ -f ${key_file}.pub ]; then
	echo_error_and_exit "${script_name}: Error: ${key_file}.pub already exists."
fi

ssh-keygen -C ${comment} -f ${key_file} -N "" || exit 1
if [ ${verbose} == yes ]; then
	echo ""
	echo_info "${key_file}.pub contains:"
	cat ${key_file}.pub
fi

exit 0
