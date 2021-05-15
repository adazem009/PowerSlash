#!/bin/bash

disout="$1"
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
		q=0
		space=0
		if ((i3 < ${#arg})); then
			i3="$(($i3+1))"
		fi
		until [[ "${arg:$(($i3-1)):1}" = "[" ]] || ((i3 == ${#arg})); do
			i3="$(($i3+1))"
			if [[ "${arg:$(($i3-1)):1}" = ' ' ]]; then
				space=1
			fi
			if [[ "${arg:$(($i3-1)):1}" != "[" ]] && ((space == 0)) && [[ "${arg:$(($i3-1)):1}" != "!" ]]; then
				args[$(($argid-1))]="${args[$(($argid-1))]}${arg:$(($i3-1)):1}"
			elif [[ "${arg:$(($i3-1)):1}" = "!" ]]; then
				negate2="$(($negate2+1))"
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
						if [[ "$disout" != "1" ]]; then
							print_info "Using 1 input in a condition." 1 4
						fi
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
					if [[ "${arg:0:1}" = '"' ]] || [[ "${arg:0:1}" = "'" ]]; then
						qs="${arg:0:1}"
					else
						qs=""
					fi
					until ((i4 == lentemp)); do
						if [[ "${arg:$(($i4-1)):1}" = "$qs" ]]; then
							q=$((1-q))
							if ((q == 0)); then
								if [[ "${arg:${i4}:1}" = '"' ]] || [[ "${arg:${i4}:1}" = "'" ]]; then
									qs="${arg:${i4}:1}"
								else
									qs=""
								fi
							fi
						fi
						if [[ "${args[0]:$(($i4-1)):1}" = ' ' ]] && ((q == 0)); then
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
				temp0='"' temp1="'"
				if [[ "${temp4[0]}" == *'"'* ]]; then
					#full0="${temp1}${temp4[0]}${temp1}"
					full0="${temp4[0]}"
				else
					#full0="${temp0}${temp4[0]}${temp0}"
					full0="${temp4[0]}"
				fi
				if [[ "${temp4[2]}" == *'"'* ]]; then
					#full2="${temp1}${temp4[2]}${temp1}"
					full2="${temp4[2]}"
				else
					#full2="${temp0}${temp4[2]}${temp0}"
					full2="${temp4[2]}"
				fi
				final="${final}/${full0},${temp0}${temp4[1]}${temp0},${full2}"
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
				if [[ "$disout" != "1" ]]; then
					print_info "No gate used." 1
				fi
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
						if [[ "$disout" != "1" ]]; then
							print_info "Using 1 input in a condition." 1 4
						fi
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
						if [[ "${args[2]:$(($i4-1)):1}" = "$qs" ]]; then
							q=0 qs=""
						fi
						if [[ "${args[2]:$(($i4-1)):1}" = '"' ]] || [[ "${args[2]:$(($i4-1)):1}" = "'" ]]; then
							if [[ "$qs" = "" ]]; then
								q=1 qs="${args[2]:$(($i4-1)):1}"
							fi
						fi
						if [[ "${args[2]:$(($i4-1)):1}" = ' ' ]] && ((q == 0)); then
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
		process_argument "${command[1]}"
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the first argument must be 1." 1 10
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
		i4=0
		while ((i4 < ifs)); do
			i4=$((i4+1))
			echo 5 >> "./output/$FILE"
		done
		ifs=0
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
		ifs=$((ifs+1))
		;;
	"print")
		# Print.
		if ((${#command[@]} != 2)); then
			abort_compiling "Number of arguments must be 1." 1 1
		fi
		i4=0
		process_argument "${command[1]}"
		bold=""
		italic=""
		underlined=""
		col=0
		while ((i4 < ${#argument[@]})); do
			i4="$(($i4+1))"
			backslash="${argument[$(($i4-1))]}"
			backslash="${backslash:0:1}${backslash:1:1}"
			if [[ "$backslash" = "\n" ]]; then
				if [[ "$arch" = "lithium" ]]; then
					echo n >> "./output/$FILE"
					echo 0 >> "./output/$FILE"
				else
					echo "E" >> "./output/$FILE"
				fi
			elif [[ "$backslash" = "\c" ]] && [[ "$arch" != "lithium" ]]; then
				color=""
				i5=2
				while ((i5 < ${#argument[$(($i4-1))]})); do
					i5=$((i5+1))
					arg="${argument[$(($i4-1))]}"
					color="${color}${arg:$((i5-1)):1}"
				done
				quote='"'
				col=1
				echo "21/${color}" >> "./output/$FILE"
			elif [[ "$backslash" = "\b" ]] && [[ "$arch" != "lithium" ]]; then
				arg="${argument[$(($i4-1))]}"
				i5=2 bold=""
				while ((i5 < ${#argument[$(($i4-1))]})); do
					i5=$((i5+1))
					bold="${bold}${arg:$((i5-1)):1}"
				done
			elif [[ "$backslash" = "\i" ]] && [[ "$arch" != "lithium" ]]; then
				arg="${argument[$(($i4-1))]}"
				i5=2 italic=""
				while ((i5 < ${#argument[$(($i4-1))]})); do
					i5=$((i5+1))
					italic="${italic}${arg:$((i5-1)):1}"
				done
			elif [[ "$backslash" = "\u" ]] && [[ "$arch" != "lithium" ]]; then
				arg="${argument[$(($i4-1))]}"
				i5=2 underlined=""
				while ((i5 < ${#argument[$(($i4-1))]})); do
					i5=$((i5+1))
					underlined="${underlined}${arg:$((i5-1)):1}"
				done
			elif [[ "${backslash:0:1}" = '\' ]]; then
				abort_compiling "Invalid backslash escape." 1 16
			else
				if [[ "$bold" = "" ]] && [[ "$italic" = "" ]] && [[ "$underlined" = "" ]]; then
					if [[ "$arch" = "lithium" ]]; then
						echo p >> "./output/$FILE"
						echo 1 >> "./output/$FILE"
						process_input "${argument[$(($i4-1))]}"
						echo "$input_type" >> "./output/$FILE"
						echo "$input" >> "./output/$FILE"
					else
						echo "A/${argument[$(($i4-1))]}" >> "./output/$FILE"
					fi
				else
					if [[ "$arch" = "lithium" ]]; then
						abort_compiling "Unknown backslash escape error." 1 16
					else
						echo "A/${argument[$(($i4-1))]}/${bold},${italic},${underlined}" >> "./output/$FILE"
					fi
				fi
			fi
		done
		if ((col == 1)); then
			quote='"'
			echo "21/${quote}255255255${quote}" >> "./output/$FILE"
		fi
		;;
	"read")
		# Read.
		if ((${#command[@]} == 0)); then
			abort_compiling "No arguments." 1 1
		fi
		i3=1
		while ((i3 < ${#command[@]})); do
			i3="$(($i3+1))"
			process_argument "${command[$(($i3-1))]}"
			if (( ${#argument[@]} != 2 )); then
				case "${i3:$((${#i3}-1)):1}" in
					1)
						tmp0=st
						;;
					2)
						tmp0=nd
						;;
					3)
						tmp0=rd
						;;
					*)
						tmp0=th
						;;
				esac
				abort_compiling "Number of inputs in the ${i3}${tmp0} argument must be 2." 1 10
			fi
			if [[ "$arch" = "lithium" ]]; then
				echo "B" >> "./output/$FILE"
				echo 2 >> "./output/$FILE"
				i5=0
				while ((i5 < 2)); do
					i5=$((i5+1))
					process_input "${argument[$((i5-1))]}"
					echo "$input_type" >> "./output/$FILE"
					echo "$input" >> "./output/$FILE"
				done
			else
				echo "B/${command[$(($i3-1))]}" >> "./output/$FILE"
			fi
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
		process_argument2 "${command[1]}"
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
		i4=1
		while ((i4 < ${#command[@]})); do
			i4="$(($i4+1))"
			final="${final}/${command[$(($i4-1))]}"
			process_argument "${command[$(($i4-1))]}"
			num=$(($i4-1))
			if ((${#argument[@]} < 2)); then
				case ${num:$((${#num}-1)):1} in
					1)
						tmp0=st
						;;
					2)
						tmp0=nd
						;;
					3)
						tmp0=rd
						;;
					*)
						tmp0=th
						;;
				esac
				abort_compiling "Number of inputs in the ${num}${tmp0} argument must be at least 2." 1 10
			fi
		done
		echo "$final" >> "./output/$FILE"
		;;
	"round")
		# Round.
		if ((${#command[@]} != 3)); then
			abort_compiling "Number of arguments must be 2." 1 1
		fi
		process_argument "${command[1]}"
		if ((${#argument[@]} != 2)); then
			abort_compiling "Number of inputs in the first argument must be 2." 1 10
		fi
		echo "11/${command[1]}/${command[2]}" >> "./output/$FILE"
		;;
	"while")
		# While loop.
		if ((${#command[@]} == 0)); then
			abort_compiling "No arguments." 1 1
		fi
		process_if 7
		;;
	"getletter")
		# Get letter of a string and save it in variable(s).
		if ((${#command[@]} != 3)); then
			abort_compiling "Number of arguments must be 2." 1 1
		fi
		process_argument "${command[1]}"
		if ((${#argument[@]} != 2)); then
			abort_compiling "Number of inputs in the first argument must be 2." 1 10
		fi
		process_argument "${command[2]}"
		if ((${#argument[@]} == 0)); then
			abort_compiling "Number of inputs in the second argument must be at least 1." 1 10
		fi
		echo "12/${command[1]}/${command[2]}" >> "./output/$FILE"
		;;
	"getlength")
		# Get length of a string and save it in variable(s).
		if ((${#command[@]} != 3)); then
			abort_compiling "Number of arguments must be 2." 1 1
		fi
		process_argument "${command[1]}"
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the first argument must be 1." 1 10
		fi
		process_argument "${command[2]}"
		if ((${#argument[@]} == 0)); then
			abort_compiling "Number of inputs in the second argument must be at least 1." 1 10
		fi
		echo "13/${command[1]}/${command[2]}" >> "./output/$FILE"
		;;
	"setlist")
		# Setup list(s).
		if ((${#command[@]} != 2)) && ((${#command[@]} != 3)); then
			abort_compiling "Number of arguments must be 1 or 2." 1 1
		fi
		process_argument "${command[1]}"
		if ((${#argument[@]} == 0)); then
			abort_compiling "Number of inputs in the first argument must be at least 1." 1 10
		fi
		echo "14/${command[1]}/${command[2]}" >> "./output/$FILE"
		;;
	"append")
		# Append to list.
		if ((${#command[@]} != 3)); then
			abort_compiling "Number of arguments must be 2." 1 1
		fi
		process_argument "${command[1]}"
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the first argument must be 1." 1 10
		fi
		process_argument "${command[2]}"
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the second argument must be 1." 1 10
		fi
		echo "15/${command[1]}/${command[2]}" >> "./output/$FILE"
		;;
	"replace")
		# Replace item in list.
		if ((${#command[@]} != 3)); then
			abort_compiling "Number of arguments must be 2." 1 1
		fi
		process_argument "${command[1]}"
		if ((${#argument[@]} != 2)); then
			abort_compiling "Number of inputs in the first argument must be 2." 1 10
		fi
		process_argument "${command[2]}"
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the second argument must be 1." 1 10
		fi
		echo "16/${command[1]}/${command[2]}" >> "./output/$FILE"
		;;
	"insert")
		# Insert item to list.
		if ((${#command[@]} != 3)); then
			abort_compiling "Number of arguments must be 2." 1 1
		fi
		process_argument "${command[1]}"
		if ((${#argument[@]} != 2)); then
			abort_compiling "Number of inputs in the first argument must be 2." 1 10
		fi
		process_argument "${command[2]}"
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the second argument must be 1." 1 10
		fi
		echo "17/${command[1]}/${command[2]}" >> "./output/$FILE"
		;;
	"getitem")
		# Get item from list.
		if ((${#command[@]} != 3)); then
			abort_compiling "Number of arguments must be 2." 1 1
		fi
		process_argument "${command[1]}"
		if ((${#argument[@]} != 2)); then
			abort_compiling "Number of inputs in the first argument must be 2." 1 10
		fi
		process_argument "${command[2]}"
		if ((${#argument[@]} == 0)); then
			abort_compiling "Number of inputs in the second argument must be at least 1." 1 10
		fi
		echo "18/${command[1]}/${command[2]}" >> "./output/$FILE"
		;;
	"getlistlength")
		# Get length of list.
		if ((${#command[@]} != 3)); then
			abort_compiling "Number of arguments must be 2." 1 1
		fi
		process_argument "${command[1]}"
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the first argument must be 1." 1 10
		fi
		process_argument "${command[2]}"
		if ((${#argument[@]} == 0)); then
			abort_compiling "Number of inputs in the second argument must be at least 1." 1 10
		fi
		echo "19/${command[1]}/${command[2]}" >> "./output/$FILE"
		;;
	"define")
		# Function definition.
		if ((${#command[@]} != 2)); then
			abort_compiling "Number of arguments must be 1." 1 1
		fi
		process_argument "${command[1]}"
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the first argument must be 1." 1 10
		fi
		if ((def != 0)); then
			abort_compiling "Can't define a function inside another function." 1 12
		fi
		def=$i1
		if [[ "${argument[0]:0:1}" != '"' ]] && [[ "${argument[0]:0:1}" != "'" ]]; then
			abort_compiling "Can't get function name from a variable." 1 15
		fi
		process_argument2 "${command[1]}"
		defname="${argument[0]}"
		deftype="cp"
		if [ -f "./.functions/$defname" ]; then
			abort_compiling "Command or function '${defname}' already exists." 1 14
		fi
		rm "./output/${FILE}.old" && cp "./output/$FILE" "./output/${FILE}.old"
		;;
	"linkdef")
		# Linkable (library) function definition.
		if ((${#command[@]} != 2)); then
			abort_compiling "Number of arguments must be 1." 1 1
		fi
		process_argument "${command[1]}"
		if ((${#argument[@]} != 1)) && ((${#argument[@]} != 2)) && ((${#argument[@]} != 3)); then
			abort_compiling "Number of inputs in the first argument must be 1, 2 or 3." 1 10
		fi
		if ((def != 0)); then
			abort_compiling "Can't define a function inside another function." 1 12
		fi
		def=$i1
		deftype="lib"
		if [[ "${argument[0]:0:1}" != '"' ]] && [[ "${argument[0]:0:1}" != "'" ]]; then
			abort_compiling "Can't get function name from a variable." 1 15
		fi
		if [[ "${argument[1]}" != "" ]]; then
			if [[ "${argument[1]:0:1}" != '"' ]] && [[ "${argument[1]:0:1}" != "'" ]]; then
				abort_compiling "Can't get library ID from a variable." 1 15
			fi
		fi
		if [[ "${argument[2]}" != "" ]]; then
			if [[ "${argument[2]:0:1}" != '"' ]] && [[ "${argument[2]:0:1}" != "'" ]]; then
				abort_compiling "Can't get library type from a variable." 1 15
			fi
		fi
		process_argument2 "${command[1]}"
		defname="${argument[0]}"
		last_libid="${argument[1]}"
		if ((last_libid > 0)) && (( last_libid <= $((libid+1)) )); then
			abort_compiling "Conflicting library ID. Numbers are not recommended!" 1 15
		fi
		if [[ "${argument[2]}" = "" ]]; then
			lib_type="local"
		else
			case "${argument[2]}" in
				"local")
					lib_type="local"
					;;
				"global")
					lib_type="global"
					;;
				*)
					abort_compiling "Unknown library type '${argument[2]}'" 1 15
					;;
			esac
		fi
		if [ -f "./.functions/$defname" ]; then
			abort_compiling "Command or function '${defname}' already exists." 1 14
		fi
		rm "./output/${FILE}.old" && cp "./output/$FILE" "./output/${FILE}.old"
		;;
	"{")
		# Function definition start.
		if ((${#command[@]} > 1)); then
			abort_compiling "Number of arguments must be 0." 1 1
		fi
		if ((func == 1)); then
			abort_compiling "Can't start a function definition inside another function." 1 12
		fi
		if (($((def+1)) != i1)); then
			abort_compiling "Unexpected token '{'." 1 13
		fi
		func=1
		defstart="$(wc -l < "./output/$FILE")"
		;;
	"}")
		# Function definition end.
		if ((${#command[@]} > 1)); then
			abort_compiling "Number of arguments must be 0." 1 1
		fi
		if ((func == 0)) || ((def == 0)); then
			abort_compiling "Unexpected token '}'." 1 13
		fi
		def=0
		func=0
		i4=$defstart
		len="$(wc -l < "./output/$FILE")"
		if [[ "$deftype" = "lib" ]] && [ -f ".tmp" ]; then
			rm .tmp
		fi
		while ((i4 < len)); do
			i4=$((i4+1))
			tmp0='!'
			if [[ "$deftype" = "lib" ]]; then
				echo "$(sed "${i4}${tmp0}d" "./output/$FILE")" >> "./.tmp"
			else
				echo "$(sed "${i4}${tmp0}d" "./output/$FILE")" >> "./.functions/$defname"
			fi
		done
		rm "./output/$FILE" && mv "./output/${FILE}.old" "./output/$FILE" && touch "./output/${FILE}.old"
		if [[ "$deftype" = "lib" ]]; then
			source ./parts/upgrade.sh 1 ../.tmp
			if [[ "$last_libid" = "" ]]; then
				libid=$((libid+1))
				cur_libid="$libid"
			else
				cur_libid="$last_libid"
			fi
			IFS=$'\r\n' GLOBIGNORE='*' command eval  'smc=($(cat ./.tmp))'
			image=""
			convi=0
			while (( convi < ${#smc[@]} )); do
				convi=$((convi+1))
				line="${smc[$((convi-1))]}"
				len=${#line}
				image="${image}${len};${line}"
			done
			if [[ "$lib_type" = "global" ]]; then
				prefix='$'
			else
				prefix=""
			fi
			echo ">>" >> "./output/$FILE"
			echo "${prefix}tmp_lib_$cur_libid" >> "./output/$FILE"
			echo "$image" >> "./output/$FILE"
			echo "1B/${prefix}tmp_lib_$cur_libid" > .functions/$defname
			rm .tmp
		fi
		if [[ "$disout" != "1" ]]; then
			print_info "Compiled function '${defname}'." 1
		fi
		#if [[ "$disout" != "1" ]]; then
		#	cat "./.functions/$defname"
		#fi
		;;
	"run")
		# Run binary.
		if ((${#command[@]} < 2)); then
			abort_compiling "Number of arguments must be at least 1." 1 1
		fi
		process_argument "${command[1]}"
		if ((${#argument[@]} == 0)); then
			abort_compiling "Number of inputs in the first argument must be at least 1." 1 10
		fi
		final="1A/${command[1]}/${command[2]}"
		i2=3
		while ((i2 < ${#command[@]})); do
			i2="$(($i2+1))"
			final="${final}/${command[$(($i2-1))]}"
		done
		echo "$final" >> "./output/$FILE"
		;;
	"source")
		# Source - share variables and lists with another binary.
		if ((${#command[@]} < 2)); then
			abort_compiling "Number of arguments must be at least 1." 1 1
		fi
		process_argument "${command[1]}"
		if ((${#argument[@]} == 0)); then
			abort_compiling "Number of inputs in the first argument must be at least 1." 1 10
		fi
		final="1B/${command[1]}/${command[2]}"
		i2=3
		while ((i2 < ${#command[@]})); do
			i2="$(($i2+1))"
			final="${final}/${command[$(($i2-1))]}"
		done
		echo "$final" >> "./output/$FILE"
		;;
	"getkey")
		# Get currently pressed keys and save them in a list.
		if ((${#command[@]} != 2)); then
			abort_compiling "Number of arguments must be 1." 1 1
		fi
		process_argument "${command[1]}"
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the first argument must be 1." 1 10
		fi
		echo "1C/${command[1]}" >> "./output/$FILE"
		;;
	"bgcolor")
		# Set background color.
		if ((${#command[@]} != 2)); then
			abort_compiling "Number of arguments must be 1." 1 1
		fi
		process_argument "${command[1]}"
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the first argument must be 1." 1 10
		fi
		echo "1D/${command[1]}" >> "./output/$FILE"
		;;
	"warp")
		# Run a group of commands without screen refresh.
		if ((${#command[@]} != 1)); then
			abort_compiling "Number of arguments must be 0." 1 1
		fi
		echo "1E" >> "./output/$FILE"
		;;
	"endwarp")
		# End warp.
		if ((${#command[@]} != 1)); then
			abort_compiling "Number of arguments must be 0." 1 1
		fi
		echo "1F" >> "./output/$FILE"
		;;
	"wait")
		# Wait.
		if ((${#command[@]} != 2)); then
			abort_compiling "Number of arguments must be 1." 1 1
		fi
		process_argument "${command[1]}"
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the first argument must be 1." 1 10
		fi
		echo "20/${command[1]}" >> "./output/$FILE"
		;;
	"listdisk")
		# List disks and save to list.
		if ((${#command[@]} != 2)); then
			abort_compiling "Number of arguments must be 1." 1 1
		fi
		process_argument "${command[1]}"
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the first argument must be 1." 1 10
		fi
		echo "22/${command[1]}" >> "./output/$FILE"
		;;
	"createdisk")
		# Create disk.
		if ((${#command[@]} != 2)); then
			abort_compiling "Number of arguments must be 1." 1 1
		fi
		process_argument "${command[1]}"
		if ((${#argument[@]} != 2)); then
			abort_compiling "Number of inputs in the first argument must be 2." 1 10
		fi
		echo "23/${command[1]}" >> "./output/$FILE"
		;;
	"rmdisk")
		# Remove disk.
		if ((${#command[@]} != 2)); then
			abort_compiling "Number of arguments must be 1." 1 1
		fi
		process_argument "${command[1]}"
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the first argument must be 1." 1 10
		fi
		echo "24/${command[1]}" >> "./output/$FILE"
		;;
	"renamedisk")
		# Rename disk.
		if ((${#command[@]} != 2)); then
			abort_compiling "Number of arguments must be 1." 1 1
		fi
		process_argument "${command[1]}"
		if ((${#argument[@]} != 2)); then
			abort_compiling "Number of inputs in the first argument must be 2." 1 10
		fi
		echo "25/${command[1]}" >> "./output/$FILE"
		;;
	"beep")
		# Beep.
		if ((${#command[@]} != 2)); then
			abort_compiling "Number of arguments must be 1." 1 1
		fi
		process_argument "${command[1]}"
		if ((${#argument[@]} != 2)); then
			abort_compiling "Number of inputs in the first argument must be 2." 1 10
		fi
		echo "26/${command[1]}" >> "./output/$FILE"
		;;
	"deleteitem")
		# Remove item from list.
		if ((${#command[@]} != 3)); then
			abort_compiling "Number of arguments must be 2." 1 1
		fi
		process_argument "${command[1]}"
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the first argument must be 1." 1 10
		fi
		process_argument "${command[2]}"
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the second argument must be 1." 1 10
		fi
		echo "27/${command[1]}/${command[2]}" >> "./output/$FILE"
		;;
	"getdisksize")
		# Get disk size.
		if ((${#command[@]} != 3)); then
			abort_compiling "Number of arguments must be 2." 1 1
		fi
		process_argument "${command[1]}"
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the first argument must be 1." 1 10
		fi
		process_argument "${command[2]}"
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the second argument must be 1." 1 10
		fi
		echo "28/${command[1]}/${command[2]}" >> "./output/$FILE"
		;;
	"showlogo")
		# Show SMC Computer splash screen.
		if ((${#command[@]} != 1)); then
			abort_compiling "Number of arguments must be 0." 1 1
		fi
		echo "29/1" >> "./output/$FILE"
		;;
	"hidelogo")
		# Hide SMC Computer splash screen.
		if ((${#command[@]} != 1)); then
			abort_compiling "Number of arguments must be 0." 1 1
		fi
		echo "29/0" >> "./output/$FILE"
		;;
	"enabletext")
		# Enable text on screen.
		if ((${#command[@]} != 1)); then
			abort_compiling "Number of arguments must be 0." 1 1
		fi
		echo "2A/1" >> "./output/$FILE"
		;;
	"disabletext")
		# Disable text on screen.
		if ((${#command[@]} != 1)); then
			abort_compiling "Number of arguments must be 0." 1 1
		fi
		echo "2A/0" >> "./output/$FILE"
		;;
	"shutdown")
		# Shut down.
		if ((${#command[@]} != 1)); then
			abort_compiling "Number of arguments must be 0." 1 1
		fi
		echo "2B/1" >> "./output/$FILE"
		;;
	"reboot")
		# Reboot.
		if ((${#command[@]} != 1)); then
			abort_compiling "Number of arguments must be 0." 1 1
		fi
		echo "2B/2" >> "./output/$FILE"
		;;
	"writedisk")
		# Direct disk write.
		if ((${#command[@]} != 3)); then
			abort_compiling "Number of arguments must be 2." 1 1
		fi
		process_argument "${command[1]}"
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the first argument must be 1." 1 10
		fi
		process_argument "${command[2]}"
		if ((${#argument[@]} != 2)); then
			abort_compiling "Number of inputs in the second argument must be 2." 1 10
		fi
		echo "2C/${command[1]}/${command[2]}" >> "./output/$FILE"
		;;
	"loadcode")
		# Load PC code.
		if ((${#command[@]} != 2)); then
			abort_compiling "Number of arguments must be 1." 1 1
		fi
		process_argument "${command[1]}"
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the first argument must be 1." 1 10
		fi
		echo "2D/${command[1]}" >> "./output/$FILE"
		;;
	"leavebios")
		# Disable BIOS setup mode.
		if ((${#command[@]} != 1)); then
			abort_compiling "Number of arguments must be 0." 1 1
		fi
		echo "2E" >> "./output/$FILE"
		;;
	"readdisk")
		# Disable BIOS setup mode.
		if ((${#command[@]} != 3)); then
			abort_compiling "Number of arguments must be 2." 1 1
		fi
		process_argument "${command[1]}"
		if ((${#argument[@]} != 2)); then
			abort_compiling "Number of inputs in the first argument must be 2." 1 10
		fi
		process_argument "${command[2]}"
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the second argument must be 1." 1 10
		fi
		echo "2E" >> "./output/$FILE"
		;;
	"print>")
		# Multi-line print start
		if ((${#command[@]} > 2)); then
			abort_compiling "Number of arguments must be 0 or 1." 1 1
		fi
		cch=0
		if ((${#command[@]} == 2)); then
			process_argument "${command[1]}"
			if ((${#argument[@]} != 1)); then
				abort_compiling "Number of inputs in the second argument must be 1." 1 10
			fi
			cch=1
			echo "21/${argument[0]}" >> "./output/$FILE"
		fi
		oldi=$i1 && suc=0
		while (( i1 < ${#PRG[@]} )); do
			i1=$((i1+1))
			line="${PRG[$((i1-1))]}" && str="" && i2=0
			se=0
			while (( i2 <  ${#line} )); do
				i2=$((i2+1))
				ch="${line:$((i2-1)):1}"
				if [[ "$ch" != ' ' ]] && [[ "$ch" != '	' ]] || ((se == 1)); then
					se=1
					str="${str}${ch}"
				fi
			done
			if [[ "$str" = '<print' ]]; then
				suc=1
				break
			else
				if [[ "$str" != '""' ]] && [[ "$str" != "''" ]]; then
					echo "A/$str" >> "./output/$FILE"
				fi
				echo "E" >> "./output/$FILE"
			fi
		done
		if ((suc == 0)); then
			i1=$oldi
			abort_compiling "print>: Unexpected end of file. Maybe '<print' is missing?" 1 16
		fi
		if ((cch == 1)); then
			echo "21/255255255" >> "./output/$FILE"
		fi
		;;
	"<print")
		# Multi-line print end
		# Nothing here
		:
		;;
	"showcplist")
		# Show copy list.
		if ((${#command[@]} != 2)); then
			abort_compiling "Number of arguments must be 1." 1 1
		fi
		process_argument "${command[1]}"
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the first argument must be 1." 1 10
		fi
		echo "30/${command[1]}" >> "./output/$FILE"
		;;
	"hidecplist")
		# Hide copy list.
		if ((${#command[@]} != 1)); then
			abort_compiling "Number of arguments must be 0." 1 1
		fi
		echo "31" >> "./output/$FILE"
		;;
	"cpdisk")
		# Copy disk data to variable.
		if ((${#command[@]} != 3)); then
			abort_compiling "Number of arguments must be 2." 1 1
		fi
		process_argument "${command[1]}"
		if ((${#argument[@]} != 1)) && ((${#argument[@]} != 2)); then
			abort_compiling "Number of inputs in the first argument must be 1 or 2." 1 10
		fi
		process_argument "${command[2]}"
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the second argument must be 1." 1 10
		fi
		echo "32/${command[1]}/${command[2]}" >> "./output/$FILE"
		;;
	"bintolist")
		# Convert binary to list.
		if ((${#command[@]} != 3)); then
			abort_compiling "Number of arguments must be 2." 1 1
		fi
		process_argument "${command[1]}"
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the first argument must be 1." 1 10
		fi
		process_argument "${command[2]}"
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the second argument must be 1." 1 10
		fi
		echo "33/${command[1]}/${command[2]}" >> "./output/$FILE"
		;;
	"listtobin")
		# Convert list to binary.
		if ((${#command[@]} != 3)); then
			abort_compiling "Number of arguments must be 2." 1 1
		fi
		process_argument "${command[1]}"
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the first argument must be 1." 1 10
		fi
		process_argument "${command[2]}"
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the second argument must be 1." 1 10
		fi
		echo "34/${command[1]}/${command[2]}" >> "./output/$FILE"
		;;
	"readvar")
		# Read variable.
		if ((${#command[@]} != 3)); then
			abort_compiling "Number of arguments must be 2." 1 1
		fi
		process_argument "${command[1]}"
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the first argument must be 1." 1 10
		fi
		process_argument "${command[2]}"
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the second argument must be 1." 1 10
		fi
		echo "35/${command[1]}/${command[2]}" >> "./output/$FILE"
		;;
	"getindex")
		# Get index of an item.
		if ((${#command[@]} != 3)); then
			abort_compiling "Number of arguments must be 2." 1 1
		fi
		process_argument "${command[1]}"
		if ((${#argument[@]} != 2)); then
			abort_compiling "Number of inputs in the first argument must be 2." 1 10
		fi
		process_argument "${command[2]}"
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the second argument must be 1." 1 10
		fi
		echo "36/${command[1]}/${command[2]}" >> "./output/$FILE"
		;;
	"smc_getarg")
		# Interpret SMC instruction (get argument(s)).
		if ((${#command[@]} != 3)); then
			abort_compiling "Number of arguments must be 2." 1 1
		fi
		process_argument "${command[1]}"
		if ((${#argument[@]} != 6)); then
			abort_compiling "Number of inputs in the first argument must be 6." 1 10
		fi
		process_argument "${command[2]}"
		if ((${#argument[@]} != 3)); then
			abort_compiling "Number of inputs in the second argument must be 3." 1 10
		fi
		echo "37/${command[1]}/${command[2]}" >> "./output/$FILE"
		;;
	"add")
		# Calculate sum.
		if ((${#command[@]} != 3)) && ((${#command[@]} != 4)); then
			abort_compiling "Number of arguments must be 2 or 3." 1 1
		fi
		process_argument "${command[1]}"
		if ((${#argument[@]} != 2)); then
			abort_compiling "Number of inputs in the first argument must be 2." 1 10
		fi
		process_argument "${command[2]}"
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the second argument must be 1." 1 10
		fi
		process_argument "${command[3]}"
		if ((${#argument[@]} != 0)) && ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the second argument must be 0 or 1." 1 10
		fi
		echo "F/1/${command[2]}/${command[1]}/${command[3]}" >> "./output/$FILE"
		;;
	"sub")
		# Subtract.
		if ((${#command[@]} != 3)) && ((${#command[@]} != 4)); then
			abort_compiling "Number of arguments must be 2 or 3." 1 1
		fi
		process_argument "${command[1]}"
		if ((${#argument[@]} != 2)); then
			abort_compiling "Number of inputs in the first argument must be 2." 1 10
		fi
		process_argument "${command[2]}"
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the second argument must be 1." 1 10
		fi
		process_argument "${command[3]}"
		if ((${#argument[@]} != 0)) && ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the second argument must be 0 or 1." 1 10
		fi
		echo "F/2/${command[2]}/${command[1]}/${command[3]}" >> "./output/$FILE"
		;;
	"multi")
		# Multiply.
		if ((${#command[@]} != 3)) && ((${#command[@]} != 4)); then
			abort_compiling "Number of arguments must be 2 or 3." 1 1
		fi
		process_argument "${command[1]}"
		if ((${#argument[@]} != 2)); then
			abort_compiling "Number of inputs in the first argument must be 2." 1 10
		fi
		process_argument "${command[2]}"
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the second argument must be 1." 1 10
		fi
		process_argument "${command[3]}"
		if ((${#argument[@]} != 0)) && ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the second argument must be 0 or 1." 1 10
		fi
		echo "F/3/${command[2]}/${command[1]}/${command[3]}" >> "./output/$FILE"
		;;
	"div")
		# Divide.
		if ((${#command[@]} != 3)) && ((${#command[@]} != 4)); then
			abort_compiling "Number of arguments must be 2 or 3." 1 1
		fi
		process_argument "${command[1]}"
		if ((${#argument[@]} != 2)); then
			abort_compiling "Number of inputs in the first argument must be 2." 1 10
		fi
		process_argument "${command[2]}"
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the second argument must be 1." 1 10
		fi
		process_argument "${command[3]}"
		if ((${#argument[@]} != 0)) && ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the second argument must be 0 or 1." 1 10
		fi
		echo "F/4/${command[2]}/${command[1]}/${command[3]}" >> "./output/$FILE"
		;;
	"mod")
		# Calculate remainder after dividing.
		if ((${#command[@]} != 3)) && ((${#command[@]} != 4)); then
			abort_compiling "Number of arguments must be 2 or 3." 1 1
		fi
		process_argument "${command[1]}"
		if ((${#argument[@]} != 2)); then
			abort_compiling "Number of inputs in the first argument must be 2." 1 10
		fi
		process_argument "${command[2]}"
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the second argument must be 1." 1 10
		fi
		process_argument "${command[3]}"
		if ((${#argument[@]} != 0)) && ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the second argument must be 0 or 1." 1 10
		fi
		echo "F/5/${command[2]}/${command[1]}/${command[3]}" >> "./output/$FILE"
		;;
	"abs")
		# Calculate absolute value.
		if ((${#command[@]} != 3)); then
			abort_compiling "Number of arguments must be 2." 1 1
		fi
		process_argument "${command[1]}"
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the first argument must be 1." 1 10
		fi
		process_argument "${command[2]}"
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the second argument must be 1." 1 10
		fi
		echo "38/${command[1]}/${command[2]}" >> "./output/$FILE"
		;;
	"include")
		# Include.
		# This is defined in compile.sh
		:
		;;
	"getletterindex")
		# Get index of a letter in a string.
		if ((${#command[@]} != 3)); then
			abort_compiling "Number of arguments must be 2." 1 1
		fi
		process_argument "${command[1]}"
		if ((${#argument[@]} != 2)); then
			abort_compiling "Number of inputs in the first argument must be 2." 1 10
		fi
		process_argument "${command[2]}"
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the second argument must be 1." 1 10
		fi
		echo "39/${command[1]}/${command[2]}" >> "./output/$FILE"
		;;
	"replacedisk")
		# Replace disk.
		if ((${#command[@]} != 3)); then
			abort_compiling "Number of arguments must be 2." 1 1
		fi
		process_argument "${command[1]}"
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the first argument must be 1." 1 10
		fi
		process_argument "${command[2]}"
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the second argument must be 1." 1 10
		fi
		echo "3A/${command[1]}/${command[2]}" >> "./output/$FILE"
		;;
	"insmedia")
		# Insert media.
		if ((${#command[@]} != 2)); then
			abort_compiling "Number of arguments must be 1." 1 1
		fi
		process_argument "${command[1]}"
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the first argument must be 1." 1 10
		fi
		echo "3B/${command[1]}" >> "./output/$FILE"
		;;
	"smc_skiploop")
		# SMC interpreting - skip loop.
		if ((${#command[@]} != 3)); then
			abort_compiling "Number of arguments must be 2." 1 1
		fi
		process_argument "${command[1]}"
		if ((${#argument[@]} != 6)); then
			abort_compiling "Number of inputs in the first argument must be 6." 1 10
		fi
		process_argument "${command[2]}"
		if ((${#argument[@]} != 4)); then
			abort_compiling "Number of inputs in the first argument must be 4." 1 10
		fi
		echo "3C/${command[1]}" >> "./output/$FILE"
		;;
	"smc_skipif")
		# SMC interpreting - skip if.
		if ((${#command[@]} != 3)); then
			abort_compiling "Number of arguments must be 2." 1 1
		fi
		process_argument "${command[1]}"
		if ((${#argument[@]} != 6)); then
			abort_compiling "Number of inputs in the first argument must be 6." 1 10
		fi
		process_argument "${command[2]}"
		if ((${#argument[@]} != 4)); then
			abort_compiling "Number of inputs in the first argument must be 4." 1 10
		fi
		echo "3D/${command[1]}" >> "./output/$FILE"
		;;
	"")
		# Comment.
		if [[ "$disout" != "1" ]]; then
			print_info "Skipping comment." 1
		fi
		;;
	*)
		if [ -f "./.functions/${command[0]}" ]; then
			if [[ "$disout" != "1" ]]; then
				print_info "Found function '${command[0]}'." 1
			fi
			tmp0='"'
			i4=1
			while ((i4 < ${#command[@]})); do
				i4=$((i4+1))
				echo "14/${tmp0}arg_$((i4-1))${tmp0}" >> "./output/$FILE"
				process_argument "${command[$((i4-1))]}"
				i5=0
				while ((i5 < ${#argument[@]})); do
					i5=$((i5+1))
					echo "15/${argument[$((i5-1))]}/${tmp0}arg_$((i4-1))${tmp0}" >> "./output/$FILE"
				done
			done
			echo "10/${tmp0}arg_count${tmp0},$((${#command[@]}-1))" >> "./output/$FILE"
			i4=0
			len="$(wc -l < "./.functions/${command[0]}")"
			while ((i4 < len)); do
				i4=$((i4+1))
				tmp0='!'
				echo "$(sed "${i4}${tmp0}d" "./.functions/${command[0]}")" >> "./output/$FILE"
			done
		else
			contains=0
			i4=0
			while ((i4 < ${#functions})); do
				i4=$((i4+1))
				if [[ "${functions[$((i4-1))]}" = "${command[0]}" ]]; then
					contains=1
				fi
			done
			if ((contains == 1)); then
				echo "${command[0]}" >> "./output/$FILE"
			else
				abort_compiling "Command or function '${command[0]}' not found." 1 8
			fi
		fi
		;;
esac
