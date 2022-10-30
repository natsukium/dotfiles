function nix-shell --description "A wrapper of nix-shell for fish called from .bashrc"
    argparse --ignore-unknown 'command=' 'run=' -- $argv
    or return

    set -lq _flag_run
    or set -l _flag_run "fish"

    if set -lq _flag_command
        command nix-shell $argv --run $_flag_run --command $_flag_command
    else
        command nix-shell $argv --run $_flag_run
    end
end
