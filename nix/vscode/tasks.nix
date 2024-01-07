let
  presentation = {
    echo = false;
    reveal = "always";
    focus = true;
    panel = "new";
    close = true;
  };
in
{
  version = "2.0.0";
  tasks = [
    {
      label = "file preview";
      type = "shell";
      command = "fd --type f --color always --strip-cwd-prefix | fzf --ansi --layout reverse --preview 'bat --style=numbers,header,grid --color=always --line-range :200 {}' | xargs code -r";
      inherit presentation;
      problemMatcher = [ ];
    }
    {
      label = "fuzzy search";
      type = "shell";
      command = ''
        RG_PREFIX='rg --column --line-number --no-heading --color=always --smart-case '; INITIAL_QUERY="''${*:-}"; IFS=: read -ra selected < <(FZF_DEFAULT_COMMAND="$RG_PREFIX $(printf %q "$INITIAL_QUERY")" fzf --ansi --layout reverse --color "hl:-1:underline,hl+:-1:underline:reverse" --disabled --query "$INITIAL_QUERY" --bind "change:reload:sleep 0.1; $RG_PREFIX {q} || true" --bind "ctrl-f:unbind(change,ctrl-f)+change-prompt(2. fzf> )+enable-search+clear-query+rebind(ctrl-r)" --bind "ctrl-r:unbind(ctrl-r)+change-prompt(1. ripgrep> )+disable-search+reload($RG_PREFIX {q} || true)+rebind(change,ctrl-f)" --prompt '1. Ripgrep> ' --delimiter : --header '/ CTRL-R (Ripgrep mode) / CTRL-F (fzf mode) /' --preview 'bat --color=always {1} --highlight-line {2}' --preview-window 'border-left,+{2}+3/3,~3'); [ -n "''${selected[0]}" ] && code -r -g "''${selected[0]}:''${selected[1]}"
      '';
      inherit presentation;
      problemMatcher = [ ];
    }
    {
      label = "open active tab";
      type = "shell";
      command = ''
        STORE_PATH=$(dirname "$(rg ''${workspaceFolder}\" ~/Library/Application\ Support/Code/User/workspaceStorage -l)"); sqlite3 "''${STORE_PATH}/state.vscdb" 'SELECT value FROM ItemTable WHERE key == "memento/workbench.parts.editor"' | jq -r -C '."editorpart.state".serializedGrid.root.data[].data.editors[].value' | jq -r -C '.resourceJSON.fsPath' | grep -v null | fzf --ansi --layout reverse --preview 'bat --style=numbers,header,grid --color=always --line-range :200 {}' | xargs code -r
      '';
      inherit presentation;
      problemMatcher = [ ];
    }
  ];
}
