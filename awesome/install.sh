#!/bin/sh
#
# Awesome WM (awesome.naquadah.org)
#
# This creates a symlink for rc.lua depending on the dotfile
# created with script/bootstrap.

# Includes
source "$HOME/.dotfiles/script/helpers.sh"

# Variables
source_dir="$HOME/.dotfiles/awesome"
source_file1="blingbling"
source_file11="lib"
source_dir2=$HOME
source_file2=".rc.lua"
target_dir="$HOME/.config/awesome"
target_file="rc.lua"

set -e

# Check if source_dir exists
if ! [ -d $source_dir ]
then
    fail "Directory '$source_dir' not existing. Are the git submodules initialized?"
fi

# Create directory if it doesn't exist
create_directory $target_dir

# Create symlink for blingbling
create_symlink $source_dir $source_file1 $target_dir $source_file1
# Create symlink for lib
create_symlink $source_dir $source_file11 $target_dir $source_file11

# Create symlink for rc.lua
create_symlink $source_dir2 $source_file2 $target_dir $target_file

success 'Finished installing awesome config'
