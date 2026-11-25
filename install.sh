#!/usr/bin/env bash

SCRIPT_VERSION=9.0.0

SCRIPT_NAME=$(basename ${BASH_SOURCE[0]})
SCRIPT_DIR=$(dirname ${BASH_SOURCE[0]})
SCRIPT_PATH=${BASH_SOURCE[0]}

function echo_usage()
{
	echo "${SCRIPT_NAME} - Version ${SCRIPT_VERSION}"
	echo ""
	echo "Install the bash-environment framework."
	echo ""
	echo "Usage: ${SCRIPT_NAME} [options]"
	echo ""
	echo "Options:"
	echo "      --help     Output this help information."
	echo "  -v, --version  Output the version."
}

# ANSI color escape sequences for use in echo_color().
BLACK='\e[30m'
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
MAGENTA='\e[35m'
CYAN='\e[36m'
WHITE='\e[37m'
RESET='\e[0m'

# Echo a color message.
# Echoing ANSI escape codes for color works, yet tput does not.
# This may be caused by tput not being able to determine the terminal type.
# Usage: echo_color color message
function echo_color()
{
	local color=${1}
	local message=${2}
	echo -e "${color}${message}${RESET}"
}

# Echo an informational message.
# Usage: echo_info message
function echo_info()
{
	local message=${1}
	echo_color ${CYAN} "${message}"
}

# Echo an error message.
# Usage: echo_error message
function echo_error()
{
	local message=${1}
	echo_color ${RED} "${SCRIPT_NAME}: Error: ${message}"
}

# Echo an error message and exit.
# Usage: echo_error_and_exit message
function echo_error_and_exit()
{
	local message=${1}
	echo_error "${message}"
	exit 1
}

# Copy a file without inheriting the source file mode.
# Set the destination file mode after copying.
# Usage: copy_and_mode mode src_file dst_file
function copy_and_mode()
{
	local mode=${1}
	local src=${2}
	local dst=${3}
	echo_info "Copying ${src} to ${dst} ..."
	cp --no-preserve=mode ${src} ${dst}
	echo_info "Setting mode for ${dst} to ${mode} ..."
	chmod ${mode} ${dst}
}

# Parse the options using GNU getopt.
# On Mac OS X and FreeBSD, you have to install GNU getopt separately.
GETOPT_SHORT_OPTIONS="v"
GETOPT_LONG_OPTIONS="help,version"
PARSED_ARGS=$(getopt -o ${GETOPT_SHORT_OPTIONS} -l ${GETOPT_LONG_OPTIONS} -n ${SCRIPT_NAME} -- "${@}")
return_code=${?}
if [ ${return_code} -ne 0 ]; then
	echo_error_and_exit "getopt returned ${return_code}" >&2
fi

# Re-index positional arguments to match parsed structure.
# The quotes around "${PARSED_ARGS}" are necessary.
eval set -- "${PARSED_ARGS}"

# Parse the command line arguments.
while true; do
	case "${1}" in
		--help)
			echo_usage
			exit 0
			;;
		-v | --version)
			echo "${SCRIPT_VERSION}"
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
		echo_error "Invalid argument -- '${1}'" >&2
		shift
	done
	exit 1
fi

# Install or update ${HOME}/bin.
if [ ! -d ${HOME}/bin ]; then
	echo_info "Creating ${HOME}/bin ..."
	mkdir -p ${HOME}/bin
fi
copy_and_mode u+x ${SCRIPT_DIR}/bin/create-gitconfig.sh ${HOME}/bin/create-gitconfig.sh
copy_and_mode u+x ${SCRIPT_DIR}/bin/create-ssh-key.sh ${HOME}/bin/create-ssh-key.sh
copy_and_mode u+x ${SCRIPT_DIR}/bin/git-clone.sh ${HOME}/bin/git-clone.sh
copy_and_mode u+x ${SCRIPT_DIR}/bin/source-bashrc.d-scripts.sh ${HOME}/bin/source-bashrc.d-scripts.sh

# Install or update ~/.bashrc.d.
if [ ! -d ${HOME}/.bashrc.d ]; then
	echo_info "Creating ${HOME}/.bashrc.d ..."
	mkdir -p ${HOME}/.bashrc.d
fi
copy_and_mode u+x ${SCRIPT_DIR}/.bashrc.d/home-bin.sh ${HOME}/.bashrc.d/home-bin.sh
copy_and_mode u+x ${SCRIPT_DIR}/.bashrc.d/misc-aliases.sh ${HOME}/.bashrc.d/misc-aliases.sh
copy_and_mode u+x ${SCRIPT_DIR}/.bashrc.d/misc-vars.sh ${HOME}/.bashrc.d/misc-vars.sh

# Text lines that delimit the hook in ~/.bashrc.
BLOCK_START='# bash-environment - Start of block'
BLOCK_END='# bash-environment - End of block'
BLOCK_WARNING='# Do not remove or modify any of the lines in this block.'

# Install or replace the hook in ~/.bashrc.
sed -i "/^${BLOCK_START}/,/^${BLOCK_END}/d" ${HOME}/.bashrc
echo "${BLOCK_START}" >> ${HOME}/.bashrc
echo "${BLOCK_WARNING}" >> ${HOME}/.bashrc
cat << 'EOF' >> ${HOME}/.bashrc
source ${HOME}/bin/source-bashrc.d-scripts.sh
EOF
echo "${BLOCK_END}" >> ${HOME}/.bashrc

exit 0
