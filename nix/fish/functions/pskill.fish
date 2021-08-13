function pskill
    ps aux | fzf | awk '{print $2}' | read -l pid; and kill $pid
    if test $status -eq 0
        echo process $pid was killed
    else
        :
    end
end
