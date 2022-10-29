[
  {
    key = "ctrl+n";
    command = "editor.action.triggerSuggest";
    when = "!suggestWidgetMultipleSuggestions && vim.mode == 'Insert'";
  }
  {
    key = "ctrl+p";
    command = "editor.action.triggerSuggest";
    when = "!suggestWidgetMultipleSuggestions && vim.mode == 'Insert'";
  }
  {
    key = "ctrl+f";
    command = "acceptSelectedSuggestion";
    when = "suggestWidgetVisible && textInputFocus";
  }
  {
    key = "ctrl+e";
    command = "hideSuggestWidget";
    when = "suggestWidgetVisible && textInputFocus";
  }
  {
    # VSCodeVimで上書きされているようなのでデフォルトで上書き
    key = "ctrl+n";
    command = "workbench.action.quickOpenSelectNext";
    when = "inQuickOpen";
  }
  {
    # VSCodeVimで上書きされているようなのでデフォルトで上書き
    key = "ctrl+p";
    command = "workbench.action.quickOpenSelectPrevious";
    when = "inQuickOpen";
  }
  {
    key = "ctrl+[";
    command = "workbench.action.closeQuickOpen";
    when = "inQuickOpen";
  }
  {
    key = "ctrl+w l";
    command = "workbench.action.focusActiveEditorGroup";
    when = "sideBarFocus";
  }
  {
    key = "ctrl+w ctrl+l";
    command = "workbench.action.focusActiveEditorGroup";
    when = "sideBarFocus";
  }
  {
    key = "ctrl+w k";
    command = "workbench.action.focusActiveEditorGroup";
    when = "panelFocus";
  }
  {
    key = "ctrl+w ctrl+k";
    command = "workbench.action.focusActiveEditorGroup";
    when = "panelFocus";
  }
  {
    key = "ctrl+i";
    command = "tab";
    when = "editorFocus && vim.mode == 'Insert";
  }
  {
    key = "ctrl+[";
    command = "extension.vim_escape";
    when = "editorFocus";
  }
  {
    key = "ctrl+t";
    command = "workbench.action.terminal.new";
    when = "terminalProcessSupported";
  }
  {
    key = "ctrl+shift+`";
    command = "-workbench.action.terminal.new";
    when = "terminalProcessSupported";
  }
]
