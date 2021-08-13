function fzfz
    z -l | awk '{print $2}' | fzf | read -l result; and cd $result
end

bind \cs 'fzfz'
