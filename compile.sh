#!/bin/bash

# PowerSlash to SMC compiler
# 2020 - adazem09
#
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
	touch .functions/linkdef
	touch ".functions/{"
	touch ".functions/}"
	touch .functions/run
	touch .functions/source
	touch .functions/getkey
	touch .functions/bgcolor
	touch .functions/warp
	touch .functions/endwarp
	touch .functions/wait
	touch .functions/listdisk
	touch .functions/createdisk
	touch .functions/rmdisk
	touch .functions/renamedisk
	touch .functions/beep
	touch .functions/deleteitem
	touch .functions/getdisksize
	touch .functions/showlogo
	touch .functions/hidelogo
	touch .functions/enabletext
	touch .functions/disabletext
	touch .functions/shutdown
	touch .functions/reboot
	touch .functions/writedisk
	touch .functions/loadcode
	touch .functions/leavebios
	touch .functions/readdisk
	touch ".functions/print>"
	touch ".functions/<print"
	touch .functions/showcplist
	touch .functions/hidecplist
	touch .functions/cpdisk
	touch .functions/bintolist
	touch .functions/listtobin
	touch .functions/readvar
	touch .functions/getindex
	touch .functions/smc_getarg
	touch .functions/add
	touch .functions/sub
	touch .functions/multi
	touch .functions/div
	touch .functions/mod
	touch .functions/abs
	touch .functions/include
}
process_command ()
{
	local cmd="$1"
	command=()
	temp=""
	i2=0
	while ((i2 < ${#cmd})); do
		# Command/function name
#		if [[ "${cmd:$i2:1}" = " " ]] || [[ "${cmd:$i2:1}" = "	" ]]; then
#			i2="$(($i2+1))"
#		fi
#		while [[ "${cmd:$((i2-1)):1}" = " " ]] || [[ "${cmd:$((i2-1)):1}" = "	" ]]; do
#			i2="$(($i2+1))"
#		done
		cur=""
		while ((i2 < ${#cmd})) && [[ "$cur" != "/" ]]; do
			i2="$(($i2+1))"
			if [[ "${cmd:$((i2-1)):1}" = '"' ]] || [[ "${cmd:$((i2-1)):1}" = "'" ]]; then
				if ((ign == 0)); then
					abort_compiling "Invalid command/function name." 1 "-3"
				fi
			fi
			if [[ "${cmd:$((i2-1)):1}" != "/" ]]; then
				if [[ "${cmd:$((i2-1)):1}" != " " ]] && [[ "${cmd:$((i2-1)):1}" != "	" ]]; then
					temp="${temp}${cmd:$((i2-1)):1}"
				fi
			fi
			cur="${cmd:$((i2-1)):1}"
		done
		command[${#command[@]}]="$temp"
		temp=""
		while ((i2 < ${#cmd})); do
			i2="$(($i2+1))"
			if [[ "${cmd:$((i2-1)):1}" = '"' ]] || [[ "${cmd:$((i2-1)):1}" = "'" ]]; then
				temp="${temp}${cmd:$((i2-1)):1}"
				quote="${cmd:$((i2-1)):1}"
				cur=""
				while ((i2 < ${#cmd})) && [[ "$cur" != "$quote" ]]; do
					i2="$(($i2+1))"
					cur="${cmd:$((i2-1)):1}"
					temp="${temp}$cur"
				done
			elif [[ "${cmd:$((i2-1)):1}" = "/" ]]; then
				command[${#command[@]}]="$temp"
				temp=""
			else
				temp="${temp}${cmd:$((i2-1)):1}"
			fi
		done
	done
	if [[ "$temp" != "" ]]; then
		command[${#command[@]}]="$temp"
	fi
	ign=0
}
process_argument ()
{
	cmd="$1"
	argument=()
	temp=""
	i2=0
	if true; then #[[ "$cmd" != "" ]]; then
		while ((i2 < ${#cmd})); do
			i2="$(($i2+1))"
			if [[ "${cmd:$((i2-1)):1}" = '"' ]] || [[ "${cmd:$((i2-1)):1}" = "'" ]]; then
				temp="${temp}${cmd:$((i2-1)):1}"
				quote="${cmd:$((i2-1)):1}"
				cur=""
				while ((i2 < ${#cmd})) && [[ "$cur" != "$quote" ]]; do
					i2="$(($i2+1))"
					cur="${cmd:$((i2-1)):1}"
					temp="${temp}$cur"
				done
				argument[${#argument[@]}]="$temp"
				temp=""
			elif [[ "${cmd:$((i2-1)):1}" = "," ]]; then
				if [[ "$temp" != "" ]]; then
					argument[${#argument[@]}]="$temp"
				fi
				temp=""
			else
				temp="${temp}${cmd:$((i2-1)):1}"
			fi
		done
		if [[ "$temp" != "" ]]; then
			argument[${#argument[@]}]="$temp"
		fi
	fi
}
process_argument2 ()
{
	cmd="$1"
	argument=()
	temp=""
	i2=0
	while ((i2 < ${#cmd})); do
		i2="$(($i2+1))"
		if [[ "${cmd:$((i2-1)):1}" = '"' ]] || [[ "${cmd:$((i2-1)):1}" = "'" ]]; then
			temp="${temp}${cmd:$((i2-1)):1}"
			temp2=""
			quote="${cmd:$((i2-1)):1}"
			cur=""
			while ((i2 < ${#cmd})) && [[ "$cur" != "$quote" ]]; do
				i2="$(($i2+1))"
				cur="${cmd:$((i2-1)):1}"
				if [[ "$cur" != "$quote" ]]; then
					temp2="${temp2}$cur"
				fi
				temp="${temp}$cur"
			done
			if [[ "$temp" = "$temp2" ]]; then
				abort_compiling "Cannot pass variable." 1 "-4"
			fi
			argument[${#argument[@]}]="$temp2"
			temp=""
			temp2=""
		elif [[ "${cmd:$((i2-1)):1}" = "," ]]; then
			temp=""
			temp2=""
		fi
	done
}
process_input()
{
	local in="$1" pi=0 qu=0
	input=""
	if [[ "${in:0:1}" = '"' ]] || [[ "${in:0:1}" = "'" ]]; then
		pi=1 qu=1
		input_type=s
	else
		re='^-?[0-9]+([.][0-9]+)?$'
		if [[ $temp =~ $re ]]; then
			input_type=s
		else
			input_type=v
		fi
	fi
	while (( pi < $((${#in}-qu)) )); do
		pi=$((pi+1))
		input="${input}${in:$((pi-1)):1}"
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
SOURCE_FILE="$1"
EXT=""
ign=0
disout="$1"
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
if ! [[ -f "$SOURCE_FILE" ]]; then
	echo "Error: Couldn't open ${SOURCE_FILE}."
	exit -1
fi
IFS=$'\r\n' GLOBIGNORE='*' command eval  'OLDPRG=($(cat $SOURCE_FILE))'
if [[ "${PRG[0]}" = '//!Lithium' ]]; then
	arch="lithium"
	outext="bin"
else
	arch="smc"
	outext="smc"
fi
if [[ "$EXT" = "pwsl" ]] || [[ "$EXT" = "PWSL" ]]; then
	FILE="${NAME}.$outext"
elif [[ "$EXT" = "pwsle" ]] || [[ "$EXT" = "PWSLE" ]]; then
	FILE="$NAME"
else
	FILE="${SOURCE_FILE}.$outext"
fi
if [[ "$3" != "" ]]; then
	FILE="$3"
fi
echo > "./output/$FILE" && rm "./output/$FILE" && touch "./output/$FILE"
if [ -d "./.functions" ]; then
	rm -rf ./.functions
fi
mkdir ./.functions
echo > "./output/${FILE}.old" && rm "./output/${FILE}.old" && touch "./output/${FILE}.old"
cmd_db
def=0
libid=0
func=0
ifs=0
# Compile
prg_len="${#OLDPRG[@]}"
if [[ "$2" != "1" ]]; then
	print_info "Searching for includes..."
fi
PRG=()
i1=0
while (( i1 < prg_len )); do
	i1="$(($i1+1))"
	ign=1
	process_command "${OLDPRG[$(($i1-1))]}"
	if [[ "${command[0]}" = "include" ]]; then
		process_argument2 "${command[1]}"
		if [[ "$2" != "1" ]]; then
			print_info "Including '${argument[0]}'" 1
		fi
		if ! [[ -f "./include/${argument[0]}" ]]; then
			abort_compiling "${argument[0]}: File not found"
		fi
		if ! [[ -f .includes ]]; then
			touch .includes
		fi
		echo "$((`cat .includes`+1))" > .includes
		num=`cat .includes`
		chmod +x compile.sh
		./compile.sh "include/${argument[0]}" "$2" ".include_`cat .includes`" || abort_compiling "Failed to include ${argument[0]} - error $?" $?
		cat "./output/.include_$num" | tee -a "./output/$FILE" > /dev/null
		echo "$((`cat .includes`-1))" > .includes
	fi
	PRG[${#PRG[@]}]="${OLDPRG[$(($i1-1))]}"
done
if [[ "$3" = "" ]]; then
	if [[ `ls -a output | grep \.include` != "" ]]; then
		rm ./output/.include*
	fi
	if [[ -f .includes ]]; then
		rm .includes
	fi
fi
tmpid=0
prg_len="${#PRG[@]}"
if [[ "$2" != "1" ]]; then
	print_info "Searching for functions..."
fi
functions=()
i1=0
while (( i1 < prg_len )); do
	i1="$(($i1+1))"
	ign=1
	process_command "${PRG[$(($i1-1))]}"
	if [[ "${command[0]}" = "define" ]] || [[ "${command[0]}" = "linkdef" ]]; then
		process_argument2 "${command[1]}"
		if [[ "$2" != "1" ]]; then
			print_info "Found function '${argument[0]}'" 1
		fi
		functions[${#functions[@]}]="${argument[0]}"
	fi
done
if [[ "$2" != "1" ]]; then
	print_info "Compiling lines..."
fi
i1=0
while (( i1 < prg_len )); do
	i1="$(($i1+1))"
	process_command "${PRG[$(($i1-1))]}"
	if [[ "$2" != "1" ]]; then
		source ./parts/compile_command.sh
		echo -e "[ ${GREEN}OK${NC} ] Compiled line $i1"
	else
		source ./parts/compile_command.sh 1
	fi
done
chain=0
contains=1
if [[ "$2" != "1" ]]; then
		print_info "Compiling additional functions..."
fi
until ((contains == 0)) || ((chain >= 50)); do
	if [[ "$arch" = "lithium" ]]; then
		if [[ "$2" != "1" ]]; then
			print_info "Skipping because of lack of arch support."
		fi
		break
	fi
	chain=$((chain+1))
	IFS=$'\r\n' GLOBIGNORE='*' command eval  'PRG=($(cat ./output/$FILE))'
	rm "./output/$FILE"
	prg_len="${#PRG[@]}"
	i1=0
	while (( i1 < prg_len )); do
		i1="$(($i1+1))"
		contains=0
		if [[ "${PRG[$(($i1-1))]}" = ">>" ]]; then
			echo ">>" >> "./output/$FILE"
			echo "${PRG[$i1]}" >> "./output/$FILE"
			echo "${PRG[$(($i1+1))]}" >> "./output/$FILE"
			i1="$(($i1+2))"
		else
			process_command "${PRG[$(($i1-1))]}"
			ai4=0
			while ((ai4 < ${#functions})); do
				ai4=$((ai4+1))
				if [[ "${command[0]}" = "" ]]; then
					break
				fi
				if [[ "${functions[$((ai4-1))]}" = "${command[0]}" ]]; then
					contains=1
				fi
			done
			if ((contains == 1)); then
				if [[ "$2" != "1" ]]; then
					print_info "Found function '${command[0]}'"
				fi
				tmp0='"'
				ai4=1
				while ((ai4 < ${#command[@]})); do
					ai4=$((ai4+1))
					echo "14/${tmp0}arg_$((ai4-1))${tmp0}" >> "./output/$FILE"
					process_argument "${command[$((ai4-1))]}"
					i5=0
					while ((i5 < ${#argument[@]})); do
						i5=$((i5+1))
						echo "15/${argument[$((i5-1))]}/${tmp0}arg_$((ai4-1))${tmp0}" >> "./output/$FILE"
					done
				done
				echo "15/${tmp0}arg_count${tmp0},$((${#command[@]}-1))" >> "./output/$FILE"
				ai4=0
				echo "./.functions/${command[0]}"
				len="$(wc -l < "./.functions/${command[0]}")"
				while ((ai4 < len)); do
					ai4=$((ai4+1))
					tmp0='!'
					echo "$(sed "${ai4}${tmp0}d" "./.functions/${command[0]}")" >> "./output/$FILE"
				done
			else
				echo "${PRG[$(($i1-1))]}" >> "./output/$FILE"
			fi
		fi
	done
done
if ((chain >= 50)); then
	abort_compiling "Woah! I got stuck in a loop... please check your functions!" 0 -2
fi
if [[ "$2" != "1" ]]; then
	print_info "Searching for additional syntax errors..."
fi
IFS=$'\r\n' GLOBIGNORE='*' command eval  'PRG=($(cat ./output/$FILE))'
ifs=0
i1=0
while (( i1 < prg_len )); do
	if [[ "$arch" = "lithium" ]]; then
		if [[ "$2" != "1" ]]; then
			print_info "Skipping because of lack of arch support."
		fi
		break
	fi
	i1="$(($i1+1))"
	if [[ "${PRG[$(($i1-1))]}" = ">>" ]]; then
		i1="$(($i1+2))"
	else
		process_command "${PRG[$(($i1-1))]}"
		if [[ "${command[0]}" = "4" ]]; then
			ifs=$((ifs+1))
		elif [[ "${command[0]}" = "5" ]]; then
			ifs=$((ifs-1))
		fi
	fi
done
if ((ifs != 0)); then
	abort_compiling "Number of if statements doesn't equal number of endif statements." 0 -3
fi
rm -rf ./.functions
rm "./output/${FILE}.old"
if [ -f .tmp.old ]; then
	rm .tmp.old
fi
source ./parts/upgrade.sh "$2"
echo -e "[ ${GREEN}OK${NC} ] Compiled $SOURCE_FILE"
