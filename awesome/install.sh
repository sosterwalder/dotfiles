#!/bin/sh
#
# Awesome WM (awesome.naquadah.org)
#
# This creates a symlink for rc.lua depending on the dotfile
# created with script/bootstrap.

source_file="~/.rc.lua"
target_dir="~/.config/awesome"
target="rc.lua"

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
info "Creating symlink from '${source_dir}' to '${target_dir}/${target}'"
ln -sf $source_dir "${target_dir}/${target}"
success "Created symlink from '${source_dir}' to '${target_dir}/${target}'"

success 'Finished installing awesome config'
