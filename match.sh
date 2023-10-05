#!/usr/bin/env bash
# TODO: Some manual matches when it is not a 1:1 theme variant
# TODO: Rethink matching, analyze the variables that aren't lining up for clues on how to parse
if [ "${BASH_VERSINFO[0]}" -lt 4 ] || ([ "${BASH_VERSINFO[0]}" -eq 4 ] && [ "${BASH_VERSINFO[1]}" -lt 3 ]); then
    echo "Script requires bash 4.3+"
    exit 1
fi
# Check if at least two parameters are provided
if [ $# -lt 2 ]; then
    echo "Usage: $0 source.json output.json"
    exit 1
fi

source_file="$1"
output_file="$2"

# first grep FG and BG colors into arrays
mapfile -t light_colors_fg < <(grep -i 'foreground":' ./leuven.json | awk '{print tolower($0)}' | awk '!seen[$0]++')
mapfile -t light_colors_bg < <(grep -i 'background":' ./leuven.json | awk '{print tolower($0)}' | awk '!seen[$0]++')
echo "Found ${#light_colors_fg[@]} unique foreground colors in source"
echo "Found ${#light_colors_bg[@]} unique background colors in source"


# populate keys of an associated array with the colors for each
process_matches() {
    local -n light_colors="$1"
    local -n light_to_dark="$2"
    local fg_or_bg="$3"
    for light_color in "${light_colors[@]}"; do
	light=$(echo "$light_color" | grep -i -oE '#[0-9A-Fa-f]{6,8}')
	# some shiki color codes
	light_truncated="${light:0:7}"

	light_theme_match=$(grep -E -i "$fg_or_bg\s*\"$light_truncated\"" ./leuven-theme.el)
	if [ -z "$light_theme_match" ]; then
	    echo "Didn't find a match for $fg_or_bg $light_truncated"
	    continue
	fi

	if [ -n "${light_to_dark[$light]}" ]; then
	    echo "Already processed $fg_or_bg $light_truncated - skipping"
	    continue
	fi

	# split out the config line so we can use it to search the dark variant of the theme
	# and remove leading whitespace
	theme_variable="${light_theme_match#"${light_theme_match%%[![:blank:]]*}"}"
	# use everything up to the next whitespace as the key
	theme_variable="${theme_variable%% *}"
	theme_variable=$(printf "%s" "$theme_variable" | sed 's/[][()\.^$\/\\&*+?|{}]/\\&/g')
	# find the corresponding variable in the variant theme
	dark_theme_match=$(grep -m 1 -E "$theme_variable" ./leuven-dark-theme.el)
	# parse just the dark color code for the variable
	dark=$(echo "$dark_theme_match" | grep -i -oE "$fg_or_bg\s*\"#[0-9A-Fa-f]{6}\"" | grep -i -oE '#[0-9A-Fa-f]{6}')
	# if a color isn't found, print error
	if [ -z $dark ]; then
	    echo "Could not find $fg_or_bg: [$theme_variable] in variant theme"
	fi
	# if the source provided AA for alpha at the end, tack it back on for the shiki output
	if [ "${#light}" -eq 9 ]; then
	    dark+="AA"
	fi
	if [ -n "$dark" ]; then
	    echo "Adding $fg_or_bg match for $theme_variable Light: $light Dark: $dark"
	    light_to_dark["$light"]="$dark"
	fi
    done
}

# for every source color change it to use the variant color
make_variant() {
    local -n light_to_dark="$1"
    local fg_or_bg="$2"
    for light in "${!light_to_dark[@]}"; do
	dark="${light_to_dark[$light]}"
	# Define the search and replace strings
	search_string_light="$fg_or_bg\":\s*\"$light\""
	replace_string_dark="$fg_or_bg\": \"$dark\""
	# Replace the colors with the dark variants
	# the first part is case-sensitive to match lowercsat foreground/background
	# and the second part case-insensitive because we tolowered the colors
	sed -i "s/\($search_string_light\)/$replace_string_dark/I" "$output_file"

	# capitalize F or B
	fg_or_bg="${fg_or_bg^}"
	search_string_light="$fg_or_bg\":\s*\"$light\""
	replace_string_dark="$fg_or_bg\": \"$dark\""
	# Replace the colors with the dark variants
	# the first part is case-sensitive to match lowercsat foreground/background
	# and the second part case-insensitive because we tolowered the colors
	sed -i "s/\($search_string_light\)/$replace_string_dark/I" "$output_file"
    done
}

declare -A fg_light_to_dark
declare -A bg_light_to_dark
process_matches light_colors_fg fg_light_to_dark "foreground"
process_matches light_colors_bg bg_light_to_dark "background"

echo "Found ${#fg_light_to_dark[@]} foreground matches"
echo "Found ${#bg_light_to_dark[@]} background matches"


# creating variant of shiki theme
if [ -e "$output_file" ]; then
    rm "$output_file" 
fi
echo "Making a copy of $source_file as $output_file"
cp "$source_file" "$output_file"


echo "Updating colors"
make_variant fg_light_to_dark "foreground"
make_variant bg_light_to_dark "background"
echo "Done"
