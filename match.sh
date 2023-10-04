#!/usr/bin/env bash
SAVEIFS=$IFS

process_matches() {
    local -n matches="$1"
    local -n keys="$2"
    local -n values="$3"
    local fg_or_bg="$4"
    for match in ${matches[@]}; do
	# split at first :, use the first part as the key as it provides context
	part1="${match%%:*}"
	# Trim leading whitespace
	part1="${part1#"${part1%%[![:space:]]*}"}"
	# Trim trailing whitespace
	key="${part1%"${part1##*[![:space:]]}"}"
	# process the second part and extract only the color code as the value
	part2="${match#*:}"
	value=$(echo "$part2" | grep -oE 'foreground\s*"#[0-9A-Fa-f]{6}"' | grep -oE '#[0-9A-Fa-f]{6}')

	# add the key
	keys+=(key)
	# add the value
	values+=(value)
    done
}


# parse list of all colors that the shiki theme uses
light_colors=( $(grep -oE '#[0-9A-Fa-f]{6}' ./leuven.json) )
echo -e "Parsed Colors:\n${light_colors[*]}"
echo "==================================="

# grep for those colors and group by match
# as there will likely be multiple matches between fg and bg colors
# split the search into two distinct outputs, one for each usecase
fg_search=("${light_colors[@]/#/foreground(\w*) \"}")
bg_search=("${light_colors[@]/#/background(\w*) \"}")
fg_regex_pattern=$(IFS="|"; echo "${fg_search[*]}")
bg_regex_pattern=$(IFS="|"; echo "${bg_search[*]}")

# match fg and bg using the above patterns, grep returns a string
fg_matches=( "$(grep -E "$fg_regex_pattern" ./leuven-theme.el)" )
bg_matches=( "$(grep -E "$bg_regex_pattern" ./leuven-theme.el)" )

# split strings into arrays
IFS=$'\n'
fg_matches=($fg_matches)
bg_matches=($bg_matches)

declare -a fg_keys
declare -a fg_values
process_matches fg_matches fg_keys fg_values "foreground"

for k in ${fg_keys[@]}; do
    echo $k
done

#echo -e "Matched FG Keys:\n${fg_keys[*]}"
#echo "==================================="
#echo -e "Matched BG Keys:\n${bg_keys[*]}"
#echo "==================================="
	   

# duplicate shiki theme
#cp leuven.json leuven-dark.json

# replace all original colors with colors from the seleted key matches

IFS=$SAVEIFS
