# This file is auto-generated from configuration.org.
# Do not edit directly.

function __fish_launchctl_subcommands
    launchctl help 2>&1 | awk '
        /^Subcommands:$/ { inside = 1; next }
        inside && /^\t/ { name = $1; $1 = ""; sub(/^[ \t]+/, ""); print name "\t" $0 }
    '
end

function __fish_launchctl_options
    string match -q -- '-*' (commandline --current-token); or return
    set -l tokens (commandline --current-process --tokens-expanded --cut-at-cursor)
    set -q tokens[2]; or return
    # launchctl pads the flag column with a NUL byte, which awk would read as the end
    # of the line.
    launchctl help $tokens[2] 2>&1 | tr -d '\0' | awk '
        match($0, /^ +/) && RLENGTH == 8 && $1 ~ /^--?[A-Za-z0-9]/ {
            flag = $1; $1 = ""; sub(/^[ \t]+/, "")
            if ($0 == "") { pending = flag; next }
            print flag "\t" $0; pending = ""; next
        }
        pending != "" { sub(/^ +/, ""); print pending "\t" $0; pending = "" }
    '
end

function __fish_launchctl_domains
    set -l uid (id -u)
    printf '%s\n' system gui/$uid user/$uid
end

function __fish_launchctl_domain_services -a domain
    launchctl print $domain 2>/dev/null | awk '
        /^\tservices = \{$/ { inside = 1; next }
        inside && /^\t\}$/ { exit }
        inside { print $NF "\t" ($1 == 0 ? "not running" : "pid " $1) }
    '
end

function __fish_launchctl_service_targets
    set -l token (commandline --current-token)
    set -l domains (__fish_launchctl_domains)
    if set -l matched (string match -r '^(system|(?:gui|user|pid|login|session)/[0-9]+)/' -- $token)
        set domains $matched[2]
    end
    for domain in $domains
        printf "$domain/%s\n" (__fish_launchctl_domain_services $domain)
    end
end

function __fish_launchctl_labels
    launchctl list | awk 'NR > 1 { print $3 "\t" ($1 == "-" ? "not running" : "pid " $1) }'
end

set -l service_target_commands attach blame bootout debug disable enable kickstart print runstats uncache
set -l label_commands list remove start stop

complete -c launchctl -n __fish_use_subcommand -xa '(__fish_launchctl_subcommands)'
complete -c launchctl -n 'not __fish_use_subcommand' -a '(__fish_launchctl_options)'
complete -c launchctl -n "__fish_seen_subcommand_from $service_target_commands" -xa '(__fish_launchctl_service_targets)'
complete -c launchctl -n "__fish_seen_subcommand_from $label_commands" -xa '(__fish_launchctl_labels)'
complete -c launchctl -n '__fish_seen_subcommand_from print-disabled' -xa '(__fish_launchctl_domains)'
complete -c launchctl -n '__fish_seen_subcommand_from bootstrap; and __fish_is_token_n 2' -xa '(__fish_launchctl_domains)'
complete -c launchctl -n '__fish_seen_subcommand_from kill; and __fish_is_token_n 2' -xa '(kill -l)'
complete -c launchctl -n '__fish_seen_subcommand_from kill; and __fish_is_token_n 3' -xa '(__fish_launchctl_service_targets)'
