#!/usr/bin/env bash

# parse list of all colors that the shiki theme uses
light_colors=( $(grep -oE '#[0-9A-Fa-f]{6}' ./leuven.json) )
#echo -e "Parsed Colors:\n [${light_colors[*]}]"
# grep for those colors and group by match as there will likely be multiple matches
regex_pattern=$(IFS="|"; echo "${light_colors[*]}")
keys=( "$(grep -E "$regex_pattern" ./leuven-theme.el)" )

echo -e "Matched Keys:\n ${keys[*]}"
	   
# select the keys to use

# duplicate shiki theme

# replace all original colors with colors from the seleted key matches
