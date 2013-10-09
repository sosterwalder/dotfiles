#!/bin/sh
#
# Script containing various helper functions

info () {
  printf "  [ \033[00;34m..\033[0m ] $1\n"
}

user () {
  printf "\r  [ \033[0;33m?\033[0m ] $1\n"
}

success () {
  printf "\r\033[2K  [ \033[00;32mOK\033[0m ] $1\n"
}

fail () {
  printf "\r\033[2K  [\033[0;31mFAIL\033[0m] $1\n"
  echo ''
  exit
}

# Creates a directory if it doesn't exist
# create_directory(target_dir)
create_directory() {
    if [ -d "$1" ]
    then
        info "Skipping '$1', existing"
    else
        info "Creating directory '$1' if it doesn't exist"
        mkdir -p $1
        success "Created directory '$1'"
    fi  
}

# Creates a symlink if it doesn't exist
# create_directory(source_dir, source_file, target_dir, target_file)
create_symlink() {
    if [ -f "$3/$4" ] || [ -d "$3/$4" ]
    then
        info "Not creating symlink from '$3/$4', existing"
    else
        info "Creating symlink from '$1/$2' to '$3/$4'"
        ln -sf "$1/$2" "$3/$4"
        success "Created symlink from '$1/$2' to '$3/$4'"
    fi
}
