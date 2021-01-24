#!/bin/bash

# This script converts the output file to the new SMC format. For example:
# A/"Hello!"
# would be converted to:
# A
# 1
# 1
# "Hello!"
if [[ "$1" != "1" ]]; then
	echo "Converting to new SMC format..."
fi
# Rename output file
mv "./output/$FILE" "./output/${FILE}.old"
# Convert every line
IFS=$'\r\n' GLOBIGNORE='*' command eval  'out=($(cat "./output/${FILE}.old"))'
i=0
while (( i < ${#out[@]} )); do
	i=$((i+1))
	process_command "${out[$((i-1))]}"
	echo "${command[0]}" >> "./output/$FILE"
	echo "$((${#command[@]}-1))" >> "./output/$FILE"
	i10=1
	while (( i10 < ${#command[@]} )); do
		i10=$((i10+1))
		process_argument "${command[$((i10-1))]}"
		echo "${#argument[@]}" >> "./output/$FILE"
		i11=0
		while (( i11 < ${#argument[@]} )); do
			i11=$((i11+1))
			echo "${argument[$((i11-1))]}" >> "./output/$FILE"
		done
	done
	if [[ "$1" != "1" ]]; then
		echo -e "\e[1A\e[KConverting to new SMC format... line $i of ${#out[@]}..."
	fi
done
# Remove old format file
rm "./output/${FILE}.old"
