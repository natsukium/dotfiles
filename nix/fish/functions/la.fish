function la --description "List contents of directory, including hidden files in directory using long format"
    if type lsd >/dev/null 2>/dev/null
        lsd -alh $argv
    else
        ls -alh $argv
    end
end
