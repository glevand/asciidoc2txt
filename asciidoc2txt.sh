#!/usr/bin/env bash

usage() {
	local old_xtrace
	old_xtrace="$(shopt -po xtrace || :)"
	set +o xtrace

	{
		echo "${script_name} - Convert asciidoc input to text." >&2
		echo "Usage: ${script_name} [flags] [in-file|-]" >&2
		echo "Input file: '${in_file}'." >&2
		echo "Option flags:" >&2
#		echo "  -i --in-file  - Input file. Default: '${in_file}'." >&2
		echo "  -o --out-file - Output file. Default: '${out_file}'." >&2
		echo "  -h --help     - Show this help and exit."
		echo "  -v --verbose  - Verbose execution. Default: '${verbose}'."
		echo "  -g --debug    - Extra verbose execution. Default: '${debug}'."
		echo "Info:"
		print_project_info
	} >&2
	eval "${old_xtrace}"
}

process_opts() {
	local short_opts='i:o:hvg'
	local long_opts='in-file:,out-file:,help,verbose,debug'

	local opts
	opts=$(getopt --options ${short_opts} --long ${long_opts} -n "${script_name}" -- "$@")

	eval set -- "${opts}"

	while true ; do
		# echo "${FUNCNAME[0]}: (${#}) '${*}'"
		case "${1}" in
		-i | --in-file)
			in_file="${2}"
			shift 2
			;;
		-o | --out-file)
			out_file="${2}"
			shift 2
			;;
		-h | --help)
			usage=1
			shift
			;;
		-v | --verbose)
			verbose=1
			shift
			;;
		-g | --debug)
			verbose=1
			debug=1
			keep_tmp_dir=1
			set -x
			shift
			;;
		--)
			shift
			if [[ ${1:-} ]]; then
				in_file="${1:-}"
				shift
			fi
			extra_args="${*}"
			break
			;;
		*)
			echo "${script_name}: ERROR: Internal opts: '${*}'" >&2
			exit 1
			;;
		esac
	done
}

print_project_banner() {
	echo "${script_name} (@PACKAGE_NAME@) - ${start_time}"
}

print_project_info() {
	echo "  @PACKAGE_NAME@ ${script_name}"
	echo "  Version: @PACKAGE_VERSION@"
	echo "  Project Home: @PACKAGE_URL@"
}

on_exit() {
	local result=${1}
	local sec="${SECONDS}"

	set +x
	echo "${script_name}: Done: ${result}, ${sec} sec." >&2
}

on_err() {
	local f_name=${1}
	local line_no=${2}
	local err_no=${3}

	keep_tmp_dir=1
	echo "${script_name}: ERROR: function=${f_name}, line=${line_no}, result=${err_no}" >&2
	exit "${err_no}"
}

#===============================================================================
export PS4='\[\e[0;33m\]+ ${BASH_SOURCE##*/}:${LINENO}:(${FUNCNAME[0]:-main}):\[\e[0m\] '

script_name="${0##*/}"

SECONDS=0
start_time="$(date +%Y.%m.%d-%H.%M.%S)"

real_source="$(realpath "${BASH_SOURCE}")"
SCRIPT_TOP="$(realpath "${SCRIPT_TOP:-${real_source%/*}}")"

trap "on_exit 'Failed'" EXIT
trap 'on_err ${FUNCNAME[0]:-main} ${LINENO} ${?}' ERR
trap 'on_err SIGUSR1 ? 3' SIGUSR1

set -eE
set -o pipefail
set -o nounset

in_file='/dev/stdin'
out_file=''
usage=''
verbose=''
debug=''
keep_tmp_dir=''

process_opts "${@}"

if [[ ! "${out_file}" ]]; then
	if [[ -f "${in_file}" ]]; then
		out_file=${in_file%.*}.txt
	else
		out_file="/dev/stdout"
	fi
fi

if [[ "${out_file}" == '-' ]]; then
	out_file="/dev/stdout"
fi

if [[ "${in_file}" == '-' ]]; then
	in_file='/dev/stdin'
fi

if [[ ${usage} ]]; then
	usage
	trap - EXIT
	exit 0
fi

print_project_banner >&2

if [[ ${extra_args} ]]; then
	set +o xtrace
	echo "${script_name}: ERROR: Got extra args: '${extra_args}'" >&2
	usage
	exit 1
fi

if [[ -f ${in_file} ]]; then
	type="$(file -b ${in_file})"
	if [[ "${type##ASCII text*}" && "${type##UTF-8 Unicode text*}" ]]; then
		echo "${script_name}: WARNING: Input file: '${in_file}' is type '${type}'" >&2
	fi
fi

declare -A attributes
declare -a footnotes

echo -n '' > "${out_file}"

in_header=1
line_no=0
fn_counter=0
want_wxtended=''
in_extended=''
restart=''

# :extended-version:
# ifdef::extended-version[]
# endif::extended-version[]

while read -r line_in; do
	((line_no += 1))

	if [[ "${line_in:0:2}" == '//' ]]; then
		[[ ${verbose} ]] && echo "[${line_no}] comment: '${line_in}'" >&2
		continue
	fi

	if [[ ${in_header} ]]; then
		if [[ ! "${line_in}" ]]; then
			[[ ${verbose} ]] && echo "[${line_no}] skip: '${line_in}'" >&2
			continue
		fi

		# :a_key: a_value
		regex_attribute="^:([[:graph:]]*):[[:space:]]([[:graph:]]*)$"

		if [[ "${line_in}" =~ ${regex_attribute} ]]; then
			a_key="${BASH_REMATCH[1]}"
			a_value="${BASH_REMATCH[2]}"
			[[ ${verbose} ]] && echo "[${line_no}] attribute: '${a_key}' => '${a_value}'" >&2
			attributes+=([${a_key}]=${a_value})
			continue
		fi

		if [[ "${line_in:0:2}" == '= ' ]]; then
			[[ ${verbose} ]] && echo "[${line_no}] remove title: '${line_in}'" >&2
			continue
		fi

		if [[ "${line_in}" == ':extended-version:' ]]; then
			want_wxtended=1
			[[ ${verbose} ]] && echo "[${line_no}] Set want_wxtended: '${line_in}'" >&2
			continue
		fi

		remove_lines=(
			':notitle:'
			':nofooter:'
		)
		for text in "${remove_lines[@]}"; do
			if [[ "${line_in}" == "${text}" ]]; then
				[[ ${verbose} ]] && echo "[${line_no}] remove line: '${line_in}'" >&2
				restart=1
				break
			fi
		done
		if [[ ${restart} ]]; then
			restart=''
			continue
		fi

		[[ ${verbose} ]] && echo "[${line_no}] exit header" >&2
		in_header=''
	fi

	if [[ "${line_in}" == 'ifdef::extended-version[]' ]]; then
		in_extended=1
		[[ ${verbose} ]] && echo "[${line_no}] set in_extended: '${line_in}'" >&2
		continue
	fi

	if [[ "${line_in}" == 'endif::extended-version[]' ]]; then
		in_extended=''
		[[ ${verbose} ]] && echo "[${line_no}] clear in_extended: '${line_in}'" >&2
		continue
	fi

	if [[ ${in_extended} && ! ${want_wxtended} ]]; then
		[[ ${verbose} ]] && echo "[${line_no}] skip extended: '${line_in}'" >&2
		continue
	fi

	remove_lines=(
		'[%hardbreaks]'
	)
	for text in "${remove_lines[@]}"; do
		if [[ "${line_in}" == "${text}" ]]; then
			[[ ${verbose} ]] && echo "[${line_no}] remove line: '${line_in}'" >&2
			restart=1
			break
		fi
	done
	if [[ ${restart} ]]; then
		restart=''
		continue
	fi

	text=' +'
	if [[ "${line_in: -2}" == "${text}" ]]; then
		[[ ${verbose} ]] && echo "[${line_no}] remove '${text}'" >&2
		line_in="${line_in/${text}/}"
	fi

	# {a_key}[{text}]
	regex_link="\{([[:graph:]][^}]*)\}\[\{([[:graph:]][^}]*)\}\]"
	while :; do
		if [[ "${line_in}" =~ ${regex_link} ]]; then
			a_key="${BASH_REMATCH[1]}"
			text="${BASH_REMATCH[2]}"
			[[ ${verbose} ]] && echo "[${line_no}] link: a:'${a_key}' t:'${text}' => '${attributes[${a_key}]}'" >&2
			line_in="${line_in/\{${a_key}\}/${attributes[${a_key}]}}"
			line_in="${line_in/\[\{${text}\}\]/}"
			#echo "link update: '${line_in}'" >&2
		else
			break
		fi
	done

	# footnote:[{a_key}]
	regex_footnote="footnote:\[\{([[:graph:]][^}]*)\}\]"
	while :; do
		if [[ "${line_in}" =~ ${regex_footnote} ]]; then
			((fn_counter += 1))
			a_key="${BASH_REMATCH[1]}"
			[[ ${verbose} ]] && echo "[${line_no}] footnote[${fn_counter}]: '${a_key}'" >&2
			line_in="${line_in/footnote:\[\{${a_key}\}\]/[${fn_counter}]}"
			footnotes+=("${attributes[${a_key}]}")
			#echo "footnote update: '${line_in}'" >&2
		else
			break
		fi
	done

	# *text*
	regex_bold="\*([[:graph:]][^*]*)\*"
	while :; do
		if [[ "${line_in}" =~ ${regex_bold} ]]; then
			text="${BASH_REMATCH[1]}"
			[[ ${verbose} ]] && echo "[${line_no}] bold: '${text}'" >&2
			line_in="${line_in/\*${text}\*/${text}}"
			#echo "bold update: '${line_in}'" >&2
		else
			break
		fi
	done

	remove_texts=(
		'\[big\]'
	)
	for text in "${remove_texts[@]}"; do
		while :; do
			if [[ "${line_in}" =~ ${text} ]]; then
				[[ ${verbose} ]] && echo "[${line_no}] remove text: '${text}'" >&2
				line_in="${line_in/${text}/}"
				#echo "text update: '${line_in}'" >&2
			else
				break
			fi
		done
	done
	
	echo "${line_in}" >> ${out_file}

done < "${in_file}"

for ((i = 0; i < ${#footnotes[@]}; i++)); do
	echo "[$((i + 1))] ${footnotes[i]}" >> ${out_file}
done

trap "on_exit 'Success.'" EXIT
exit 0
