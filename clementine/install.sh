#!/bin/sh
#
# Clementine music player
#
# This creates a symlink for Clementine.conf depending on the dotfile
# created with script/bootstrap.

# Includes
source "$HOME/.dotfiles/script/helpers.sh"

# Variables
source_dir="$HOME/.dotfiles/clementine"
source_file="clementine.conf.symlink"
target_dir="$HOME/.config/Clementine"
target_file="Clementine.conf"

set -e

# Check if source_dir exists
if ! [ -d $source_dir ]
then
    fail "Directory '$source_dir' not existing. Are the git submodules initialized?"
fi

# Create directory if it doesn't exist
create_directory $target_dir

# Create symlink for Clementine.conf
create_symlink $source_dir $source_file $target_dir $target_file

success 'Finished installing clementine config'
