function ll --description "List contents of directory using long format"
    if type exa >/dev/null ^/dev/null
        exa -lh --git $argv
    else
        ls -lh $argv
    end
end
