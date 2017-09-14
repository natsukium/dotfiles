# alias
function vcsv
    column -s, -t < $argv | less -#2 -N -S
end
