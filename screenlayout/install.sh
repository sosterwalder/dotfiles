#!/bin/sh
#
# Screenlayouts using arandr (http://christian.amsuess.com/tools/arandr/)
#
# This  installs all screenlayouts (shell-scripts beginning with layout_) 
# found in $HOME/.dotfiles/screenlayouts to $HOME/.screenlayouts.

# Includes
source "$HOME/.dotfiles/script/helpers.sh"

# Variables
source_dir="$HOME/.dotfiles/screenlayout"
target_dir="$HOME/.screenlayout"

set -e

# Create target dir if not existing
create_directory $target_dir

# Find screenlayouts and create symlinks
find $source_dir -name 'layout_*.sh' |
while read layout
do
    layout_file=$(basename $layout)
    
    create_symlink $source_dir $layout_file $target_dir $layout_file
done

success 'Finished installing screenlayouts'
