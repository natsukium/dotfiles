function la --description "List contents of directory, including hidden files in directory using long format"
    if type exa >/dev/null ^/dev/null
        exa -alh --git $argv
    else
        ls -alh $argv
    end
end
