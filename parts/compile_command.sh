#!/bin/bash

process_if()
{
	if [[ "$1" = '' ]]; then
		final="4"
	else
		final="$1"
	fi
	arg="${command[1]}"
	args=()
	argid=0
	negate=0
	argcount=0
	i3=0
	while ((i3 < ${#arg})); do
		args=()
		negate=0
		negate2=0
		until [[ "${arg:$(($i3-1)):1}" = "[" ]]; do
			i3="$(($i3+1))"
			if [[ "${arg:$(($i3-1)):1}" = "!" ]]; then
				negate="$(($negate+1))"
			fi
			if ((i3 > ${#arg})); then
				abort_compiling "Unexpected end of line." 1 3
			fi
		done
		if ((negate > 1)); then
			abort_compiling "Only one negation can be used." 1 2
		fi
		argid=1
		until [[ "${arg:$(($i3-1)):1}" = "]" ]]; do
			i3="$(($i3+1))"
			if [[ "${arg:$(($i3-1)):1}" != "]" ]]; then
				args[$(($argid-1))]="${args[$(($argid-1))]}${arg:$(($i3-1)):1}"
			fi
			if ((i3 > ${#arg})); then
				abort_compiling "Unexpected end of line." 1 3
			fi
		done
		argid=2
		until [[ "${arg:$(($i3-1)):1}" = "[" ]] || ((i3 == ${#arg})); do
			i3="$(($i3+1))"
			if [[ "${arg:$(($i3-1)):1}" != "[" ]] && [[ "${arg:$(($i3-1)):1}" != ' ' ]] && [[ "${arg:$(($i3-1)):1}" != "!" ]]; then
				args[$(($argid-1))]="${args[$(($argid-1))]}${arg:$(($i3-1)):1}"
			elif [[ "${arg:$(($i3-1)):1}" = "!" ]]; then
				negate2="$(($negate2+1))"
			fi
			if ((i3 > ${#arg})); then
				abort_compiling "Unexpected end of line. '${args[0]}'" 1 3
			fi
		done
		if ((negate2 > 1)); then
			abort_compiling "Only one negation can be used." 1 2
		fi
		recoveryi=$i3
		argid=3
		until [[ "${arg:$(($i3-1)):1}" = "]" ]]; do
			i3="$(($i3+1))"
			if [[ "${arg:$(($i3-1)):1}" != "]" ]]; then
				args[$(($argid-1))]="${args[$(($argid-1))]}${arg:$(($i3-1)):1}"
			fi
			if ((i3 > ${#arg})); then
				abort_compiling "Unexpected end of line." 1 3
			fi
		done
		argcount="$(($argcount+1))"
		if ((argcount == 1)); then
			temp4=()
			i4=0
			while ((i4 < ${#args[0]})); do
				until [[ "${args[0]:$(($i4-1)):1}" = ' ' ]]; do
					i4="$(($i4+1))"
					if [[ "${args[0]:$(($i4-1)):1}" != ' ' ]]; then
						temp4[0]="${temp4[0]}${args[0]:$(($i4-1)):1}"
					fi
					if ((i4 > ${#args[0]})); then
						print_info "Using 1 input in a condition." 1 4
						break
					fi
				done
				if ((i4 <= ${#args[0]})); then
					i4="$(($i4+1))"
					until [[ "${args[0]:$(($i4-1)):1}" = ' ' ]]; do
						if [[ "${args[0]:$(($i4-1)):1}" != ' ' ]]; then
							temp4[1]="${temp4[1]}${args[0]:$(($i4-1)):1}"
						fi
						if ((i4 > ${#args[0]})); then
							abort_compiling "Unexpected end of argument." 1 4
						fi
						i4="$(($i4+1))"
					done
					i4="$(($i4+1))"
					lentemp="${#args[0]}"
					lentemp="$(($lentemp+1))"
					until ((i4 == lentemp)); do
						if [[ "${args[0]:$(($i4-1)):1}" = ' ' ]]; then
							abort_compiling "Unexpected space after second value." 1 5
						else
							temp4[2]="${temp4[2]}${args[0]:$(($i4-1)):1}"
						fi
						if ((i4 > ${#args[0]})); then
							abort_compiling "Unexpected end of argument." 1 4
						fi
						i4="$(($i4+1))"
					done
				fi
			done
			if [[ "${#temp4[@]}" = "1" ]]; then
				case "${temp4[0]}" in
					1)
						temp0='"'
						final="${final}/0,${temp0}==${temp0},0"
						;;
					"true")
						temp0='"'
						final="${final}/0,${temp0}==${temp0},0"
						;;
					0)
						temp0='"'
						final="${final}/0,${temp0}!=${temp0},0"
						;;
					"false")
						temp0='"'
						final="${final}/0,${temp0}!=${temp0},0"
						;;
					*)
						abort_compiling "Invalid input: ${temp4[0]}." 1 11
						;;
				esac
			else
				if [[ "${#temp4[@]}" != "3" ]]; then
					abort_compiling "Number of condition inputs must be 3 or 1." 1 6
				fi
				temp0='"'
				final="${final}/${temp4[0]},${temp0}${temp4[1]}${temp0},${temp4[2]}"
			fi
			if ((negate == 1)); then
				temp0='"!"'
				final="${final},${temp0}"
			fi
		fi
		skipgate=0
		case "${args[1]}" in
			"and")
				temp0='"&&"'
				final="${final}/${temp0}"
				;;
			"nand")
				temp0='"!&"'
				final="${final}/${temp0}"
				;;
			"or")
				temp0='"||"'
				final="${final}/${temp0}"
				;;
			"nor")
				temp0='"!|"'
				final="${final}/${temp0}"
				;;
			"xor")
				temp0='"//"'
				final="${final}/${temp0}"
				;;
			"xnor")
				temp0='"!/"'
				final="${final}/${temp0}"
				;;
			"")
				print_info "No gate used." 1
				skipgate=1
				;;
			*)
				abort_compiling "Unknown gate: ${args[1]}." 1 7
				;;
		esac
		if ((skipgate == 0)); then
			temp4=()
			i4=0
			while ((i4 < ${#args[2]})); do
				until [[ "${args[2]:$(($i4-1)):1}" = ' ' ]]; do
					i4="$(($i4+1))"
					if [[ "${args[2]:$(($i4-1)):1}" != ' ' ]]; then
						temp4[0]="${temp4[0]}${args[2]:$(($i4-1)):1}"
					fi
					if ((i4 > ${#args[2]})); then
						print_info "Using 1 input in a condition." 1 4
						break
					fi
				done
				if ((i4 <= ${#args[0]})); then
					i4="$(($i4+1))"
					until [[ "${args[2]:$(($i4-1)):1}" = ' ' ]]; do
						if [[ "${args[2]:$(($i4-1)):1}" != ' ' ]]; then
							temp4[1]="${temp4[1]}${args[2]:$(($i4-1)):1}"
						fi
						if ((i4 > ${#args[2]})); then
							abort_compiling "Unexpected end of argument." 1 4
						fi
						i4="$(($i4+1))"
					done
					i4="$(($i4+1))"
					lentemp="${#args[2]}"
					lentemp="$(($lentemp+1))"
					until ((i4 == lentemp)); do
						if [[ "${args[2]:$(($i4-1)):1}" = ' ' ]]; then
							abort_compiling "Unexpected space after second value." 1 5
						else
							temp4[2]="${temp4[2]}${args[2]:$(($i4-1)):1}"
						fi
						if ((i4 > ${#args[2]})); then
							abort_compiling "Unexpected end of argument." 1 4
						fi
						i4="$(($i4+1))"
					done
				fi
			done
			if [[ "${#temp4[@]}" = "1" ]]; then
				case "${temp4[0]}" in
					1)
						temp0='"'
						final="${final}/0,${temp0}==${temp0},0"
						;;
					"true")
						temp0='"'
						final="${final}/0,${temp0}==${temp0},0"
						;;
					0)
						temp0='"'
						final="${final}/0,${temp0}!=${temp0},0"
						;;
					"false")
						temp0='"'
						final="${final}/0,${temp0}!=${temp0},0"
						;;
					*)
						abort_compiling "Invalid input: ${temp4[0]}." 1 11
						;;
				esac
			else
				if [[ "${#temp4[@]}" != "3" ]]; then
					abort_compiling "Number of condition inputs must be 3." 1 6
				fi
				temp0='"'
				final="${final}/${temp4[0]},${temp0}${temp4[1]}${temp0},${temp4[2]}"
			fi
			if ((negate2 == 1)); then
					temp0='"!"'
					final="${final},${temp0}"
			fi
			if ((i3 < ${#arg})); then
				i3=$recoveryi
			fi
		fi
	done
	echo "$final" >> "./output/$FILE"
}
case "${command[0]}" in
	"exit")
		# The end.
		# You do NOT need to use it at the end of your program.
		if ((${#command[@]} != 1)); then
			abort_compiling "Number of arguments must be 0." 1 1
		fi
		echo 0 >> "./output/$FILE"
		;;
	"repeat")
		# Repeat n times - loop.
		if ((${#command[@]} != 2)); then
			abort_compiling "Number of arguments must be 1." 1 1
		fi
		process_argument ${command[1]}
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs must be 1." 1 10
		fi
		echo "2/${command[1]}" >> "./output/$FILE"
		;;
	"endloop")
		# The end of the last loop.
		if ((${#command[@]} != 1)); then
			abort_compiling "Number of arguments must be 0." 1 1
		fi
		echo 3 >> "./output/$FILE"
		;;
	"if")
		# If.
		# if/[! or nothing][ [value] [operator] [value] ] [gate] ...
		if ((${#command[@]} == 0)); then
			abort_compiling "No arguments." 1 1
		fi
		process_if
		;;
	"endif")
		# End if.
		if ((${#command[@]} != 1)); then
			abort_compiling "Number of arguments must be 0." 1 1
		fi
		echo 5 >> "./output/$FILE"
		;;
	"else")
		# Else.
		if ((${#command[@]} != 1)); then
			abort_compiling "Number of arguments must be 0." 1 1
		fi
		echo 6 >> "./output/$FILE"
		;;
	"elseif")
		# Else if.
		if ((${#command[@]} == 0)); then
			abort_compiling "No arguments." 1 1
		fi
		echo 6 >> "./output/$FILE"
		process_if
		;;
	"print")
		# Print.
		if ((${#command[@]} != 2)); then
			abort_compiling "Number of arguments must be 1." 1 1
		fi
		i4=0
		process_argument "${command[1]}"
		while ((i4 < ${#argument[@]})); do
			i4="$(($i4+1))"
			if [[ "${argument[$(($i4-1))]}" = "\n" ]]; then
				echo "E" >> "./output/$FILE"
			else
				echo "A/${argument[$(($i4-1))]}" >> "./output/$FILE"
			fi
		done
		;;
	"read")
		# Read.
		if ((${#command[@]} == 0)); then
			abort_compiling "No arguments." 1 1
		fi
		i2=1
		if ((${#command[@]} > 2)); then
			print_info "Using multiple read commands." 1
		fi
		while ((i2 < ${#command[@]})); do
			i2="$(($i2+1))"
			echo "B/${command[$(($i2-1))]}" >> "./output/$FILE"
		done
		;;
	"keywait")
		# Wait for keypress.
		if ((${#command[@]} != 2)); then
			abort_compiling "Number of arguments must be 1." 1 1
		fi
		echo "C/${command[1]}" >> "./output/$FILE"
		;;
	"clear")
		# Clear screen.
		if ((${#command[@]} != 1)); then
			abort_compiling "Number of arguments must be 0." 1 1
		fi
		echo "D" >> "./output/$FILE"
		;;
	"calc")
		# Calculate.
		# calc/[expression]/[scale]
		if ((${#command[@]} == 1)); then
			abort_compiling "Number of arguments must be at least 1." 1 1
		fi
		if ((${#command[@]} > 3)); then
			abort_compiling "Only expression and scale arguments can be used." 1 1
		fi
		process_argument2 ${command[1]}
		var=""
		i3=0
		until [[ "${argument[0]:$(($i3-1)):1}" = "=" ]]; do
			i3="$(($i3+1))"
			if [[ "${argument[0]:$(($i3-1)):1}" != "=" ]]; then
				var="${var}${argument[0]:$(($i3-1)):1}"
			fi
			if [[ "${argument[0]:$(($i3-1)):1}" = "+" ]] || [[ "${argument[0]:$(($i3-1)):1}" = "-" ]] || [[ "${argument[0]:$(($i3-1)):1}" = "*" ]] || [[ "${argument[0]:$(($i3-1)):1}" = "/" ]]; then
				abort_compiling "Invalid expression." 1 9
			fi
			if ((i3 > ${#argument[0]})); then
				abort_compiling "Unexpected end of line." 1 3
			fi
		done
		parts=()
		part=""
		while ((i3 < ${#argument[0]})); do
			i3="$(($i3+1))"
			if [[ "${argument[0]:$(($i3-1)):1}" = "+" ]] || [[ "${argument[0]:$(($i3-1)):1}" = "-" ]]; then
				parts[${#parts[@]}]="$part"
				parts[${#parts[@]}]="${argument[0]:$(($i3-1)):1}"
				part=""
			else
				part="${part}${argument[0]:$(($i3-1)):1}"
			fi
		done
		parts[${#parts[@]}]="$part"
		temp1=""
		i3=0
		while ((i3 < ${#parts[@]})); do
			i3="$(($i3+1))"
			parts2=()
			temp1=""
			i4=0
			while ((i4 < ${#parts[$(($i3-1))]})); do
				i4="$(($i4+1))"
				if [[ "${parts[$(($i3-1))]:$(($i4-1)):1}" = "*" ]] || [[ "${parts[$(($i3-1))]:$(($i4-1)):1}" = "/" ]]; then
					parts2[${#parts2[@]}]="${temp1}"
					parts2[${#parts2[@]}]="${parts[$(($i3-1))]:$(($i4-1)):1}"
					temp1=""
				else
					temp1="${temp1}${parts[$(($i3-1))]:$(($i4-1)):1}"
				fi
			done
			parts2[${#parts2[@]}]="${temp1}"
			final="F/"
			i4=0
			while ((i4 < ${#parts2[@]})); do
				i4="$(($i4+2))"
				case ${parts2[$(($i4-1))]} in
					"+")
						op=1
						;;
					"-")
						op=2
						;;
					"*")
						op=3
						;;
					"/")
						op=4
						;;
					*)
						op="?"
						;;
				esac
				if [[ "$op" != "?" ]]; then
					if ((i4 == 2)); then
						final="${final}${op}"
					else
						final="${final},${op}"
					fi
				fi
			done
			tmpid="$(($tmpid+1))"
			tmp0='"'
			final="${final}/${tmp0}tmp_calc${tmpid}${tmp0}/"
			i4="-1"
			while ((i4 < ${#parts2[@]})); do
				i4="$(($i4+2))"
				if ((i4 == 1)); then
					final="${final}${parts2[$(($i4-1))]}"
				else
					final="${final},${parts2[$(($i4-1))]}"
				fi
			done
			if ((${#parts2[@]} > 2)); then
				echo "$final" >> "./output/$FILE"
				parts[$(($i3-1))]="tmp_calc${tmpid}"
			fi
		done
		final="F/"
		i3=0
		while ((i3 < ${#parts[@]})); do
			i3="$(($i3+2))"
			case ${parts[$(($i3-1))]} in
				"+")
					op=1
					;;
				"-")
					op=2
					;;
				"*")
					op=3
					;;
				"/")
					op=4
					;;
				*)
					op="?"
					;;
			esac
			if [[ "$op" != "?" ]]; then
				if ((i3 == 2)); then
					final="${final}${op}"
				else
					final="${final},${op}"
				fi
			fi
		done
		tmp0='"'
		final="${final}/${tmp0}${var}${tmp0}/"
		i4="-1"
		while ((i4 < ${#parts[@]})); do
			i4="$(($i4+2))"
			if ((i4 == 1)); then
				final="${final}${parts[$(($i4-1))]}"
			else
				final="${final},${parts[$(($i4-1))]}"
			fi
		done
		if ((${#parts[@]} > 2)); then
			echo "$final" >> "./output/$FILE"
		fi
		;;
	"set")
		# Set variable(s) to value(s).
		# set/[var name],[value]/[var name],[value]/ ...
		final="10"
		i2=1
		while ((i2 < ${#command[@]})); do
			i2="$(($i2+1))"
			final="${final}/${command[$(($i2-1))]}"
		done
		echo "$final" >> "./output/$FILE"
		;;
	"while")
		# While loop.
		if ((${#command[@]} == 0)); then
			abort_compiling "No arguments." 1 1
		fi
		process_if 7
		;;
	"")
		# Comment.
		print_info "Skipping comment." 1
		;;
	*)
		abort_compiling "Command '${command[0]}' not found." 1 8
		;;
esac
