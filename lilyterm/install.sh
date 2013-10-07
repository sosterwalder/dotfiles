#!/bin/sh
#
# Lilyterm (http://lilyterm.luna.com.tw/)
#
# This creates a symlink for default.conf depending on the dotfile
# created with script/bootstrap.

source_file="$HOME/.lilyterm"
target_dir="$HOME/.config/lilyterm"
target="default.conf"

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

# Create symlink
info "Creating symlink from '${source_file}' to '${target_dir}/${target}'"
ln -sf $source_file "${target_dir}/${target}"
success "Created symlink from '${source_file}' to '${target_dir}/${target}'"

success 'Finished installing lilyterm config'
