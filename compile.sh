#!/bin/bash

# PowerSlash to SMC compiler
# 2020 - adazem09
#
### FUNCTIONS ###
#!/bin/bash

# --- Functions ---
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
IFS=$'\r\n' GLOBIGNORE='*' command eval  'PRG=($(cat $SOURCE_FILE))'
# Compile
tmpid=0
prg_len="${#PRG[@]}"
i1=0
while (( i1 < prg_len )); do
	i1="$(($i1+1))"
	process_command "${PRG[$(($i1-1))]}"
	source ./parts/compile_command.sh
	echo -e "[ ${GREEN}OK${NC} ] Compiled line $i1"
done
