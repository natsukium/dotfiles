function l --description "List contents of directory"
    if type lsd >/dev/null 2>/dev/null
        lsd $argv
    else
        ls $argv
    end
end
