function _git_branch_name
  echo (command git symbolic-ref HEAD ^/dev/null | sed -e 's|^refs/heads/||')
end

function _is_git_dirty
  echo (command git status -s --ignore-submodules=dirty ^/dev/null)
end

function fish_prompt
  set -l blue (set_color blue)
  set -l green (set_color green)
  set -l normal (set_color normal)

  set -l arrow "λ"
  set -l cwd $blue(basename (prompt_pwd))

  if [ (_git_branch_name) ]
    set git_info $green(_git_branch_name)
    set git_info ":$git_info"

    if [ (_is_git_dirty) ]
      set -l dirty "*"
      set git_info "$git_info$dirty"
    end
  end

  echo -n -s $cwd $git_info $normal ' ' $arrow ' '
end

set fish_greeting

set PATH $HOME/.n/bin $PATH
set PATH $HOME/.npm/bin $PATH
set PATH $HOME/.texlive/2014/bin/x86_64-linux $PATH

set -x EDITOR vim

eval $HOME/.config/shell.sh

if status --is-login
  if test -z "$DISPLAY" -a $XDG_VTNR = 1
    exec startx
  end
end

# Start TMUX only when parent is SSH process
if status --is-login
    set PPID (echo (ps --pid %self -o ppid --no-headers) | xargs)
    if ps --pid $PPID | grep ssh
        tmux has-session -t remote; and tmux attach-session -t remote; or tmux new-session -s remote; and kill %self
        echo "tmux failed to start; using plain fish shell"
    end
end
