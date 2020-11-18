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
		q=0
		until [[ "${arg:$(($i3-1)):1}" = "[" ]] || ((i3 == ${#arg})); do
			i3="$(($i3+1))"
			if [[ "${arg:$(($i3-1)):1}" = '"' ]]; then
				q=$((1-q))
			fi
			if [[ "${arg:$(($i3-1)):1}" != ' ' ]] && ((q == 1)); then
				c=1
			else
				c=0
			fi
			if [[ "${arg:$(($i3-1)):1}" != "[" ]] && ((c == 1)) && [[ "${arg:$(($i3-1)):1}" != "!" ]]; then
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
						if [[ "${arg:$(($i4-1)):1}" = '"' ]]; then
							q=$((1-q))
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
						if [[ "${arg:$(($i4-1)):1}" = '"' ]]; then
							q=$((1-q))
						fi
						if [[ "${args[0]:$(($i4-1)):1}" = ' ' ]] && ((q == 0)); then
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
		process_argument ${command[1]}
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
		process_argument ${command[1]}
		if ((${#argument[@]} != 2)); then
			abort_compiling "Number of inputs in the first argument must be 2." 1 10
		fi
		process_argument ${command[2]}
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
		process_argument ${command[1]}
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the first argument must be 1." 1 10
		fi
		process_argument ${command[2]}
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
		process_argument ${command[1]}
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
		process_argument ${command[1]}
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the first argument must be 1." 1 10
		fi
		process_argument ${command[2]}
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
		process_argument ${command[1]}
		if ((${#argument[@]} != 2)); then
			abort_compiling "Number of inputs in the first argument must be 2." 1 10
		fi
		process_argument ${command[2]}
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
		process_argument ${command[1]}
		if ((${#argument[@]} != 2)); then
			abort_compiling "Number of inputs in the first argument must be 2." 1 10
		fi
		process_argument ${command[2]}
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
		process_argument ${command[1]}
		if ((${#argument[@]} != 2)); then
			abort_compiling "Number of inputs in the first argument must be 2." 1 10
		fi
		process_argument ${command[2]}
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
		process_argument ${command[1]}
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the first argument must be 1." 1 10
		fi
		process_argument ${command[2]}
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
		if [[ "${argument[0]:0:1}" != '"' ]]; then
			abort_compiling "Can't get function name from a variable." 1 15
		fi
		process_argument2 "${command[1]}"
		defname="${argument[0]}"
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
			abort_compiling "Unexpected token '}'." 1 13
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
		while ((i4 < len)); do
			i4=$((i4+1))
			tmp0='!'
			echo "$(sed "${i4}${tmp0}d" "./output/$FILE")" >> "./.functions/$defname"
		done
		rm "./output/$FILE" && mv "./output/${FILE}.old" "./output/$FILE" && touch "./output/${FILE}.old"
		print_info "Compiled function '${defname}'." 1
		cat "./.functions/$defname"
		;;
	"run")
		# Run script.
		if ((${#command[@]} < 2)); then
			abort_compiling "Number of arguments must be at least 1." 1 1
		fi
		process_argument "${command[1]}"
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the first argument must be 1." 1 10
		fi
		process_argument "${command[2]}"
		if ((${#argument[@]} > 1)); then
			abort_compiling "Number of inputs in the second argument must be 1 or 0." 1 10
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
		# Source - share variables and lists with other scripts.
		if ((${#command[@]} < 2)); then
			abort_compiling "Number of arguments must be at least 1." 1 1
		fi
		process_argument "${command[1]}"
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the first argument must be 1." 1 10
		fi
		final="1B/${command[1]}"
		i2=2
		while ((i2 < ${#command[@]})); do
			i2="$(($i2+1))"
			final="${final}/${command[$(($i2-1))]}"
		done
		echo "$final" >> "./output/$FILE"
		;;
	"getfile")
		# Get file - save a file's content in a list.
		if ((${#command[@]} != 3)); then
			abort_compiling "Number of arguments must be 2." 1 1
		fi
		process_argument ${command[1]}
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the first argument must be 1." 1 10
		fi
		process_argument ${command[2]}
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs in the second argument must be 1." 1 10
		fi
		echo "1C/${command[1]}/${command[2]}" >> "./output/$FILE"
		;;
	"getkey")
		# Get currently pressed keys and save them in a list.
		if ((${#command[@]} != 2)); then
			abort_compiling "Number of arguments must be 1." 1 1
		fi
		process_argument ${command[1]}
		if ((${#argument[@]} != 1)); then
			abort_compiling "Number of inputs must be 1." 1 10
		fi
		echo "1D/${command[1]}" >> "./output/$FILE"
		;;
	"")
		# Comment.
		print_info "Skipping comment." 1
		;;
	*)
		if [ -f "./.functions/${command[0]}" ]; then
			print_info "Found function '${command[0]}'." 1
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
			echo "15/${tmp0}arg_count${tmp0},$((${#command[@]}-1))" >> "./output/$FILE"
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
