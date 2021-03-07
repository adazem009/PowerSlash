#!/bin/bash

# This script converts the output file to the new SMC format. For example:
# A/"Hello!"
# would be converted to:
# A
# 1
# 1
# "Hello!"
if [[ "$arch" = "" ]]; then
	arch=smc
fi
if [[ "$arch" = "smc" ]]; then
	if [[ "$1" != "1" ]]; then
		echo "Converting to new SMC format..."
	fi
	if [[ "$2" = "" ]]; then
		fname="$FILE"
	else
		fname="$2"
	fi
	# Rename output file
	mv "./output/$fname" "./output/${fname}.old"
	# Convert every line
	IFS=$'\r\n' GLOBIGNORE='*' command eval  'out=($(cat "./output/${fname}.old"))'
	i=0
	while (( i < ${#out[@]} )); do
		i=$((i+1))
		if [[ "${out[$((i-1))]}" = ">>" ]]; then
			echo ">>" >> "./output/$fname"
			echo "${out[$i]}" >> "./output/$fname"
			echo "${out[$((i+1))]}" >> "./output/$fname"
			i=$((i+2))
		else
			process_command "${out[$((i-1))]}"
			echo "${command[0]}" >> "./output/$fname"
			echo "$((${#command[@]}-1))" >> "./output/$fname"
			i10=1
			while (( i10 < ${#command[@]} )); do
				i10=$((i10+1))
				process_argument "${command[$((i10-1))]}"
				echo "${#argument[@]}" >> "./output/$fname"
				i11=0
				while (( i11 < ${#argument[@]} )); do
					i11=$((i11+1))
					echo "${argument[$((i11-1))]}" >> "./output/$fname"
				done
			done
			if [[ "$1" != "1" ]]; then
				echo -e "\e[1A\e[KConverting to new SMC format... line $i of ${#out[@]}..."
			fi
		fi
	done
	# Remove old format file
	rm "./output/${fname}.old"
fi
