#!/bin/sh
#
# Lilyterm (http://lilyterm.luna.com.tw/)
#
# This creates a symlink for default.conf depending on the dotfile
# created with script/bootstrap.

# Includes
source "$HOME/.dotfiles/script/helpers.sh"

# Variables
source_dir="$HOME"
source_file=".lilyterm"
target_dir="$HOME/.config/lilyterm"
target_file="default.conf"

set -e
# Create directory if it doesn't exist
create_directory $target_dir

# Create symlink if it doesn't exist
create_symlink $source_dir $source_file $target_dir $target_file

success 'Finished installing lilyterm config'
