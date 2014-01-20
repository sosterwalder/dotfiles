#!/bin/sh
#
# IRSSI (http://www.irssi.org/)
#
# This creates a symlink for config depending on the dotfile
# created with script/bootstrap.

# Includes
source "$HOME/.dotfiles/script/helpers.sh"

# Variables
source_dir="$HOME/.dotfiles/irssi"
source_file1="scripts"
source_file3="default.theme"
source_file4="xchat.theme"
source_dir2=$HOME
source_file2=".irssi_config"
target_dir="$HOME/.irssi/"
target_file="config"

set -e

# Check if source_dir exists
if ! [ -d $source_dir ]
then
    fail "Directory '$source_dir' not existing. Are the git submodules initialized?"
fi

# Create directory if it doesn't exist
create_directory $target_dir

# Create symlink for scripts
create_symlink $source_dir $source_file1 $target_dir $source_file1
# Create symlinks for themes
create_symlink $source_dir $source_file3 $target_dir $source_file3
create_symlink $source_dir $source_file4 $target_dir $source_file4

# Create symlink for config
create_symlink $source_dir2 $source_file2 $target_dir $target_file

success 'Finished installing irssi config'
