function bash
    set length (count $argv)
    if test $length -gt 1 >/dev/null
        command bash --norc -c "$argv"
    else if test $length -eq 1 >/dev/null
        command bash --norc $argv
    else
        command bash --norc
    end
    
end
