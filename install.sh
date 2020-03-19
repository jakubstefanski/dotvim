#!/usr/bin/env bash

if ((${BASH_VERSION%%.*} < 4)); then
	echo "${0} requires Bash version 4 or later" 1>&2
	exit 1
fi

set -euo pipefail

DIR="$(dirname "$(realpath "${0}")")"

declare -a new matching replaced skipped

function ensure_link() {
	local target=${1}
	local link=${2}
	local id="link ${link}" # id for printing summary

	if [ "${target}" -ef "${link}" ]; then
		matching+=("${id}")
	elif [ -e "${link}" ]; then
		local answer
		read -r -p "replace ${link} [y/N] " answer </dev/tty
		case ${answer:0:1} in
		y | Y | yes | YES)
			rm -rf "${link}"
			ln -sf "${target}" "${link}"
			replaced+=("${id}")
			;;
		*)
			skipped+=("${id}")
			;;
		esac
	else
		mkdir -p "$(dirname "${link}")"
		ln -sf "${target}" "${link}"
		new+=("${id}")
	fi
}

function should_use_colors() {
	if [[ ! -t 1 ]]; then
		return 1 # not a terminal, for example pager
	fi

	case "${TERM}" in
	xterm-color | *-256color) return 0 ;;
	esac

	if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
		return 0
	fi

	return 1
}

function print_group() {
	local name="${1}"
	shift
	local files=("${@}")

	if [ ${#files[@]} -gt 0 ]; then
		echo -e "${name}"
		printf "%s\n" "${files[@]}"
		echo
	fi
}

function print_summary() {
	local bold=''
	local red=''
	local green=''
	local blue=''
	local reset=''

	if should_use_colors; then
		bold='\e[1m'
		red='\e[31m'
		green='\e[32m'
		blue='\e[34m'
		reset='\e[0m'
	fi

	print_group "${bold}${green}New:${reset}" "${new[@]}"
	print_group "${bold}${green}Matching:${reset}" "${matching[@]}"
	print_group "${bold}${blue}Replaced:${reset}" "${replaced[@]}"
	print_group "${bold}${red}Skipped:${reset}" "${skipped[@]}"
}

function main() {
	ensure_link "${DIR}/vimrc" "${HOME}/.vimrc"
	ensure_link "${DIR}/gvimrc" "${HOME}/.gvimrc"
	ensure_link "${DIR}/vim" "${HOME}/.vim"
	print_summary
}

main "$@"
