#!/bin/sh
#
# Vundle (https://github.com/gmarik/vundle)
# Color themes
#
# This  installs vundle and colors for vim.

# Includes
source "$HOME/.dotfiles/script/helpers.sh"

# Variables
source_dir="$HOME/.dotfiles/vim"
source_file="vundle/"
target_dir="$HOME/.vim/bundle"
target_file="vundle"

set -e

# Create directory if it doesn't exist
create_directory $target_dir

# Create symlink for Vundle
create_symlink $source_dir $source_file $target_dir $target_file

success 'Finished installing vundle'

# Variables
source_file="colors/"
target_dir="$HOME/.vim"
target_file="colors"

set -e

# Create directory if it doesn't exist
create_directory $target_dir

# Create symlink for colors
create_symlink $source_dir $source_file $target_dir $target_file

success 'Finished installing colors'
