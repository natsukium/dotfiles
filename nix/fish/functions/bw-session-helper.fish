function bw-session-helper --description "A helper function for login and unlock"
    set -l _status (bw status | jq -r '.status')
    if test $_status = unauthernticated
        set -gx BW_SESSION (bw login --raw)
    else if test $_status = locked
        set -gx BW_SESSION (bw unlock --raw)
    end
end
