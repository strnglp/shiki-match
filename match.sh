#!/usr/bin/env bash
if [ "${BASH_VERSINFO[0]}" -lt 4 ] || ([ "${BASH_VERSINFO[0]}" -eq 4 ] && [ "${BASH_VERSINFO[1]}" -lt 3 ]); then
    echo "Script requires bash 4.3+"
    exit
fi


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
	value=$(echo "$part2" | grep -oE "$fg_or_bg\\s*\"#[0-9A-Fa-f]{6}\"" | grep -oE '#[0-9A-Fa-f]{6}')
	# add the key
	keys+=($key)
	# add the value
	values+=($value)
    done
}


SAVEIFS=$IFS

# parse list of all colors that the shiki theme uses
light_colors=( $(grep -oE '#[0-9A-Fa-f]{6}' ./leuven.json) )
#echo -e "Parsed Colors:\n${light_colors[*]}"
#echo "==================================="

# grep for those colors and group by match
# as there will likely be multiple matches between fg and bg colors
# split the search into two distinct outputs, one for each usecase
search=("${light_colors[@]/#/foreground(\w*) \"}")
regex_pattern=$(IFS="|"; echo "${search[*]}")
fg_matches="$(grep -E "$regex_pattern" ./leuven-theme.el)"
search=("${light_colors[@]/#/background(\w*) \"}")
regex_pattern=$(IFS="|"; echo "${search[*]}")
bg_matches="$(grep -E "$regex_pattern" ./leuven-theme.el)"

# split strings into arrays
IFS=$'\n'
fg_matches=($fg_matches)
bg_matches=($bg_matches)

declare -a fg_keys
declare -a fg_values
process_matches fg_matches fg_keys fg_values "foreground"


#end=$(( ${#fg_keys[@]} - 1 ))
#for i in $(seq 0 $end); do
#    echo  "${fg_keys[$i]} : ${fg_values[$i]}"
#done
#echo "-----------------------------------------------------"

#echo "${fg_keys[*]}"
# match the keys to the dark version
regex_pattern=$(IFS="|"; echo "${fg_keys[*]}")
fg_matches="$(grep -E '"$regex_pattern"' ./leuven-dark-theme.el)"

# missing only the first line? (code-inline '(
echo  "${fg_matches[*]}"

#end=$(( ${#fg_keys[@]} - 1 ))
#for i in $(seq 0 $end); do
#    # match each key in the dark-theme file
#    # parse the foreground color
#    # add it to the fg_dark_values
#done


#declare -a bg_keys
#declare -a bg_values
#process_matches bg_matches bg_keys bg_values "background"
#
#end=$(( ${#bg_keys[@]} - 1 ))
#for i in $(seq 0 $end); do
#done

	   

# duplicate shiki theme
#cp leuven.json leuven-dark.json

# replace all original colors with colors from the seleted key matches


IFS=$SAVEIFS
