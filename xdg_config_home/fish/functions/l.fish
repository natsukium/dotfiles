function l --description "List contents of directory"
    if type exa >/dev/null ^/dev/null
        exa $argv
    else
        ls $argv
    end
end
