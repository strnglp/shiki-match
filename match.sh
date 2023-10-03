#!/usr/bin/env bash

# parse list of all colors that the shiki theme uses
light_colors=( $(grep -oE '#[0-9A-Fa-f]{6}' ./leuven.json) )
echo -e "Parsed Colors:\n [${light_colors[*]}]"

# Construct a regex pattern for matching each color code along with the word before it
regex_pattern=$(IFS="|"; echo "(\w+\s*\S*\s*)(${light_colors[*]// /|})")
keys=$(grep -E -oz "$regex_pattern" ./leuven-theme.el)

# Replace null characters with newline characters
keys="${keys//$'\0'/$'\n'}"

# Use sed to remove non-alphanumeric characters (excluding # and newline)
cleaned_keys=$(echo "$keys" | sed -e 's/[^#[:alnum:]\n]/ /g')
echo -e "Matched Keys:\n ${cleaned_keys[*]}"
	   
# select the keys to use

# duplicate shiki theme

# replace all original colors with colors from the seleted key matches
