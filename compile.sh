#!/bin/bash

# PowerSlash to SMC compiler
# 2020 - adazem09
#
### FUNCTIONS ###
#!/bin/bash

# --- Functions ---
cmd_db ()
{
	touch .functions/exit
	touch .functions/repeat
	touch .functions/endloop
	touch .functions/if
	touch .functions/endif
	touch .functions/else
	touch .functions/elseif
	touch .functions/print
	touch .functions/read
	touch .functions/keywait
	touch .functions/clear
	touch .functions/calc
	touch .functions/set
	touch .functions/round
	touch .functions/while
	touch .functions/getletter
	touch .functions/getlength
	touch .functions/setlist
	touch .functions/append
	touch .functions/replace
	touch .functions/insert
	touch .functions/getitem
	touch .functions/getlistlength
	touch .functions/define
	touch ".functions/{"
	touch ".functions/}"
}
process_command ()
{
	local cmd="$1"
	cmdlen=${#cmd}
	command=()
	quotes=0
	temp=""
	i2=0
	while ((i2 < cmdlen)); do
		i2="$(($i2+1))"
		chartemp="$(($i2-1))"
		chartemp="${cmd:${chartemp}:1}"
		if [ "$chartemp" = '"' ]; then
			quotes="$((1-$quotes))"
		fi
		if [ "$chartemp" = "/" ] && ((quotes == 0)); then
			lentemp="${#command[@]}"
			addcmd="$temp"
			command[${#command[@]}]="$addcmd"
			temp=""
		else
			if [[ "$chartemp" != ' ' ]] && [[ "$chartemp" != '	' ]] || ((${#command[@]} > 0)); then
				temp="${temp}${chartemp}"
			fi
		fi
	done
	lentemp="${#command[@]}"
	addcmd="$temp"
	command[${#command[@]}]="$addcmd"
}
process_argument ()
{
	avalue=$1
	arglen=${#avalue}
	argument=()
	argument_translation=()
	quotes=0
	quoted=0
	temp=""
	i2=0
	while ((i2 < arglen)); do
		i2="$(($i2+1))"
		if [ "${avalue:$(($i2-1)):1}" = '"' ]; then
			quotes="$((1-$quotes))"
			quoted=1
		fi
		if [ "${avalue:$(($i2-1)):1}" = "," ] && ((quotes == 0)); then
			temp3=1
		else
			temp3=0
		fi
		if ((temp3 == 1)) || [ "$i2" = "$arglen" ]; then
			if [ "$i2" = "$arglen" ]; then
				temp="${temp}${avalue:$(($i2-1)):1}"
			fi
			if ((quoted == 1)); then
				argument_translation[${#argument_translation[@]}]="0"
			else
				argument_translation[${#argument_translation[@]}]="0"
			fi
			argument[${#argument[@]}]="$temp"
			temp=""
			quoted=0
		else
			temp="${temp}${avalue:$(($i2-1)):1}"
		fi
	done
}
process_argument2 ()
{
	avalue=$1
	arglen=${#avalue}
	argument=()
	argument_translation=()
	quotes=0
	quoted=0
	temp=""
	i2=0
	while ((i2 < arglen)); do
		i2="$(($i2+1))"
		if [ "${avalue:$(($i2-1)):1}" = '"' ]; then
			quotes="$((1-$quotes))"
			quoted=1
		fi
		if [ "${avalue:$(($i2-1)):1}" = "," ] && ((quotes == 0)); then
			temp3=1
		else
			temp3=0
		fi
		if ((temp3 == 1)) || [ "$i2" = "$arglen" ]; then
			if [ "$i2" = "$arglen" ] && [ "${avalue:$(($i2-1)):1}" != '"' ]; then
				temp="${temp}${avalue:$(($i2-1)):1}"
			fi
			if ((quoted == 1)); then
				argument_translation[${#argument_translation[@]}]="0"
			else
				argument_translation[${#argument_translation[@]}]="0"
			fi
			argument[${#argument[@]}]="$temp"
			temp=""
			quoted=0
		else
			if [ "${avalue:$(($i2-1)):1}" != '"' ]; then
				temp="${temp}${avalue:$(($i2-1)):1}"
			fi
		fi
	done
}
abort_compiling()
{
	if [[ "$2" = "1" ]]; then
		echo -e "[ ${RED}FAIL${NC} ] Line ${i1}: $1"
	else
		echo -e "[ ${RED}FAIL${NC} ] $1"
	fi
	exit $3
}
print_info()
{
	if [[ "$2" = "1" ]]; then
		echo -e "[ ${YELLOW}INFO${NC} ] Line ${i1}: $1"
	else
		echo -e "[ ${YELLOW}INFO${NC} ] $1"
	fi
}
# Init
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
SOURCE_FILE=$1
EXT=""
i1=0
while ((i1 < ${#SOURCE_FILE})); do
	i1="$(($i1+1))"
	if [[ "${SOURCE_FILE:$(($i1-1)):1}" = "." ]]; then
		NAME="$EXT"
		EXT=""
	else
		EXT="${EXT}${SOURCE_FILE:$(($i1-1)):1}"
	fi
done
if [[ "$EXT" = "$SOURCE_FILE" ]]; then
	NAME="$EXT"
	EXT=""
fi
if test -f "$SOURCE_FILE"; then
	# Nothing here
	:
else
	echo "Error: Couldn't open ${FILE}."
	exit -1
fi
if [[ "$EXT" = "pwsl" ]] || [[ "$EXT" = "PWSL" ]]; then
	FILE="${NAME}.smc"
else
	FILE="${SOURCE_FILE}.smc"
fi
echo > "./output/$FILE" && rm "./output/$FILE" && touch "./output/$FILE"
if [ -d "./.functions" ]; then
	rm -rf ./.functions
fi
mkdir ./.functions
echo > "./output/${FILE}.old" && rm "./output/${FILE}.old" && touch "./output/${FILE}.old"
cmd_db
def=0
func=0
IFS=$'\r\n' GLOBIGNORE='*' command eval  'PRG=($(cat $SOURCE_FILE))'
# Compile
tmpid=0
prg_len="${#PRG[@]}"
print_info "Searching for functions..."
functions=()
i1=0
while (( i1 < prg_len )); do
	i1="$(($i1+1))"
	process_command "${PRG[$(($i1-1))]}"
	if [[ "${command[0]}" = "define" ]]; then
		process_argument2 "${command[1]}"
		print_info "Found function '${argument[0]}'" 1
		functions[${#functions[@]}]="${argument[0]}"
	fi
done
print_info "Compiling lines..."
i1=0
while (( i1 < prg_len )); do
	i1="$(($i1+1))"
	process_command "${PRG[$(($i1-1))]}"
	source ./parts/compile_command.sh
	echo -e "[ ${GREEN}OK${NC} ] Compiled line $i1"
done
chain=0
contains=1
until ((contains == 0)) || ((chain >= 50)); do
	print_info "Compiling additional functions..."
	chain=$((chain+1))
	IFS=$'\r\n' GLOBIGNORE='*' command eval  'PRG=($(cat ./output/$FILE))'
	rm "./output/$FILE"
	prg_len="${#PRG[@]}"
	i1=0
	while (( i1 < prg_len )); do
		i1="$(($i1+1))"
		process_command "${PRG[$(($i1-1))]}"
		contains=0
		i4=0
		while ((i4 < ${#functions})); do
			i4=$((i4+1))
			if [[ "${functions[$((i4-1))]}" = "${command[0]}" ]]; then
				contains=1
			fi
		done
		if ((contains == 1)); then
			print_info "Found function '${command[0]}'"
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
			echo "${PRG[$(($i1-1))]}" >> "./output/$FILE"
		fi
	done
done
if ((chain >= 50)); then
	abort_compiling "Woah! I got stuck in a loop... please check your functions!" 0 -2
fi
echo -e "[ ${GREEN}OK${NC} ] Compiled $SOURCE_FILE"
rm -rf ./.functions
rm "./output/${FILE}.old"
