#!/bin/sh
#
# Xresources installer
#
# This merges the Xresources.solarized file
# to parse the define macros properly
# and creates a symlink for .Xresources

# Includes
source "$HOME/.dotfiles/script/helpers.sh"

# Variables
template_dir="$HOME/.dotfiles/xresources"
template_file="Xresources.solarized"
symlink_file="Xresources.symlink"
target_dir="$HOME"
target_file=".Xresources"

set -e

# Check if xrdb is installed
command -v xrdb > /dev/null 2>&1 || {
    fail "xrdb binary seems not to be installed."
}

# Check if template_dir exists
if ! [ -d $template_dir ]
then
    fail "Directory '$template_dir' not existing."
fi

# Parse/merge template file
info "Parsing and merging $template_dir/$template_file"
xrdb -merge $template_dir/$template_file

# Create output file
info "Creating output file $template_dir/$symlink_file"
xrdb -query > $template_dir/$symlink_file


# Create symlink for .Xresouces
create_symlink $template_dir $symlink_file $target_dir $target_file

success 'Finished parsing and installing .Xresources'
