#!/bin/sh
#
# Vundle (https://github.com/gmarik/vundle)
#
# This  installs vundle for vim.

source_dir="$HOME/.dotfiles/vim/vundle"
target_dir="$HOME/.vim/bundle/"

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

# Create symlink for Vundle
info "Creating symlink for vundle from '${source_dir}' to '${target_dir}'"
ln -sf $source_dir "$target_dir/."
success "Created symlink for vundle from '${source_dir}' to '${target_dir}'"

success 'Finished installing vundle'
