# Custom fish completion for just with submodule support
# This is a workaround for https://github.com/casey/just/issues/2912

# Helper function to extract recipes from a justfile JSON dump
function __fish_just_extract_recipes --argument-names json_dump
    echo "$json_dump" | jq -r '
        # Root recipes first (without ::)
        (.recipes | to_entries[] | select(.value.private != true) | "\(.value.name)\t\(.value.doc // "")"),
        # Then submodule recipes (with ::)
        (.modules | to_entries | sort_by(.key)[] | .value.recipes | to_entries[] | select(.value.private != true) | "\(.value.namepath)\t\(.value.doc // "")")
    ' 2>/dev/null
end

function __fish_just_complete_recipes
    # Check if a custom justfile is specified
    if string match -rq '(-f|--justfile)\s*=?(?<justfile>[^\s]+)' -- (string split -- ' -- ' (commandline -pc))[1]
        set -fx JUST_JUSTFILE "$justfile"
    end

    # Get the current token being completed
    set -l cur (commandline -ct)

    # Get recipes from current directory
    set -l current_json (just --dump --dump-format=json 2>/dev/null)
    set -l recipe_data (__fish_just_extract_recipes "$current_json")

    # Check if fallback is enabled and collect parent recipes
    if echo "$current_json" | jq -e '.settings.fallback == true' >/dev/null 2>&1
        set -l search_dir (pwd)
        while test "$search_dir" != /
            set search_dir (dirname "$search_dir")

            # Try to get justfile from parent directory
            set -l parent_json (just --justfile "$search_dir/justfile" --dump --dump-format=json 2>/dev/null; or just --justfile "$search_dir/.justfile" --dump --dump-format=json 2>/dev/null)

            if test -n "$parent_json"
                # Add parent recipes to the list
                set -a recipe_data (__fish_just_extract_recipes "$parent_json")

                # Check if this parent also has fallback enabled
                if not echo "$parent_json" | jq -e '.settings.fallback == true' >/dev/null 2>&1
                    break
                end
            end
        end
    end

    # If current token ends with "::", show only recipes in that module
    if string match -qr '::$' -- "$cur"
        set -l module_prefix "$cur"
        for line in $recipe_data
            set -l recipe_name (string split \t -- "$line")[1]
            if string match -q -- "$module_prefix*" "$recipe_name"
                echo "$line"
            end
        end
        return
    end

    # If current token contains "::" (but not at end), filter to matching module's recipes
    if string match -q '*::*' -- "$cur"
        set -l module_prefix (string match -r '^[^:]+::' -- "$cur")
        if test -n "$module_prefix"
            for line in $recipe_data
                set -l recipe_name (string split \t -- "$line")[1]
                if string match -q -- "$module_prefix*" "$recipe_name"
                    echo "$line"
                end
            end
            return
        end
    end

    # Output all recipes with descriptions
    printf '%s\n' $recipe_data
end

# Remove default completions for just (if any)
complete -c just -e

# Don't suggest files right off
complete -c just -n "__fish_is_first_arg" --no-files

# Complete recipes with descriptions where available
# -k (--keep-order) preserves the output order instead of sorting alphabetically
complete -c just -k -a '(__fish_just_complete_recipes)' --no-files

# Standard just options (regenerated from `just --completions fish`)
complete -c just -l alias-style -d 'Set list command alias display style' -r -f -a "left right separate"
complete -c just -l ceiling -d 'Do not ascend above <CEILING> directory' -r -F
complete -c just -l chooser -d 'Override binary invoked by `--choose`' -r
complete -c just -l color -d 'Print colorful output' -r -f -a "always auto never"
complete -c just -l command-color -d 'Echo recipe lines in <COMMAND-COLOR>' -r -f -a "black blue cyan green purple red yellow"
complete -c just -l dotenv-filename -d 'Search for environment file named <DOTENV-FILENAME>' -r
complete -c just -s E -l dotenv-path -d 'Load <DOTENV-PATH> as environment file' -r -F
complete -c just -l dump-format -d 'Dump justfile as <FORMAT>' -r -f -a "json just"
complete -c just -s f -l justfile -d 'Use <JUSTFILE> as justfile' -r -F
complete -c just -l list-heading -d 'Print <TEXT> before list' -r
complete -c just -l list-prefix -d 'Print <TEXT> before each list item' -r
complete -c just -l set -d 'Override <VARIABLE> with <VALUE>' -r
complete -c just -l shell -d 'Invoke <SHELL> to run recipes' -r
complete -c just -l shell-arg -d 'Invoke shell with <SHELL-ARG> as an argument' -r
complete -c just -l tempdir -d 'Save temporary files to <TEMPDIR>' -r -F
complete -c just -l timestamp-format -d 'Timestamp format string' -r
complete -c just -s d -l working-directory -d 'Use <WORKING-DIRECTORY> as working directory' -r -F
complete -c just -s c -l command -d 'Run an arbitrary command' -r
complete -c just -l completions -d 'Print shell completion script for <SHELL>' -r -f -a "bash elvish fish nushell powershell zsh"
complete -c just -s l -l list -d 'List available recipes' -r
complete -c just -s s -l show -d 'Show recipe at <PATH>' -r
complete -c just -l check -d 'Run `--fmt` in check mode'
complete -c just -l clear-shell-args -d 'Clear shell arguments'
complete -c just -s n -l dry-run -d 'Print what just would do without doing it'
complete -c just -l explain -d 'Print recipe doc comment before running it'
complete -c just -s g -l global-justfile -d 'Use global justfile'
complete -c just -l highlight -d 'Highlight echoed recipe lines in bold'
complete -c just -l list-submodules -d 'List recipes in submodules'
complete -c just -l no-aliases -d 'Don\'t show aliases in list'
complete -c just -l no-deps -d 'Don\'t run recipe dependencies'
complete -c just -l no-dotenv -d 'Don\'t load `.env` file'
complete -c just -l no-highlight -d 'Don\'t highlight echoed recipe lines in bold'
complete -c just -l one -d 'Forbid multiple recipes from being invoked'
complete -c just -s q -l quiet -d 'Suppress all output'
complete -c just -l allow-missing -d 'Ignore missing recipe and module errors'
complete -c just -l shell-command -d 'Invoke <COMMAND> with the shell'
complete -c just -l timestamp -d 'Print recipe command timestamps'
complete -c just -s u -l unsorted -d 'Return list and summary entries in source order'
complete -c just -l unstable -d 'Enable unstable features'
complete -c just -s v -l verbose -d 'Use verbose output'
complete -c just -l yes -d 'Automatically confirm all recipes'
complete -c just -l changelog -d 'Print changelog'
complete -c just -l choose -d 'Select recipes using a binary chooser'
complete -c just -l dump -d 'Print justfile'
complete -c just -s e -l edit -d 'Edit justfile with $VISUAL or $EDITOR'
complete -c just -l evaluate -d 'Evaluate and print all variables'
complete -c just -l fmt -d 'Format and overwrite justfile'
complete -c just -l groups -d 'List recipe groups'
complete -c just -l init -d 'Initialize new justfile in project root'
complete -c just -l man -d 'Print man page'
complete -c just -l summary -d 'List names of available recipes'
complete -c just -l variables -d 'List names of variables'
complete -c just -s h -l help -d 'Print help'
complete -c just -s V -l version -d 'Print version'
