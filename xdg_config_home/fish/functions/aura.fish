function aura
    set AURA (command aura $argv ^/dev/null)

    if echo $AURA 1>| grep -q 'check'
        sudo aura $argv
    else if echo $AURA 1>| grep -q 'root'
        sudo aura $argv
    else
        command aura $argv
    end
end
