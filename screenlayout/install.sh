#!/bin/sh
#
# Vundle (https://github.com/gmarik/vundle)
#
# This  installs vundle for vim.

source_dir="$HOME/.dotfiles/screenlayout"
target_dir="$HOME/.screenlayout"

set -e

echo ''

info () {
  printf "  [ \033[00;34m..\033[0m ] $1"
  echo ''
}

user () {
  printf "\r  [ \033[0;33m?\033[0m ] $1 "
  echo ''
}

success () {
  printf "\r\033[2K  [ \033[00;32mOK\033[0m ] $1\n"
  echo ''
}

fail () {
  printf "\r\033[2K  [\033[0;31mFAIL\033[0m] $1\n"
  echo ''
  exit
}

# Create directory if it doesn't exist
info "Creating directory '$target_dir' if it doesn't exist"
mkdir -p $target_dir
success "Created directory '$target_dir'"

# Find screenlayouts and create symlinks
find $source_dir -name 'layout_*.sh' |
while read layout
do
    layout_file=$(basename $layout)
    info "Creating symlink from '$source_dir/$layout_file' to '$target_dir/$layout_file'"
    ln -sf "$source_dir/$layout_file" "$target_dir/."
    success "Created symlink from '$source_dir/$layout_file' to '$target_dir/$layout_file'"
done

success 'Finished installing screenlayouts'
