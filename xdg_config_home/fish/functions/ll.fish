function ll --description "List contents of directory using long format"
    if type lsd >/dev/null 2>/dev/null
        lsd -lh $argv
    else
        ls -lh $argv
    end
end
