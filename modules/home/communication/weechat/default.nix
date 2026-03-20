{ pkgs, ... }:
{
  home.packages = [
    (pkgs.weechat.override {
      configure =
        { availablePlugins, ... }:
        {
          scripts = with pkgs.weechatScripts; [
            autosort
            highmon
            wee-slack
            weechat-go
          ];
          # https://github.com/NixOS/nixpkgs/blob/2ebb630421d52099270cee0ae14f4fa9ebbe3cdf/pkgs/applications/networking/irc/weechat/wrapper.nix#L20-L22
          plugins = builtins.attrValues (
            builtins.removeAttrs availablePlugins [
              "guile"
              "lua"
              "php"
              "ruby"
              "tcl"
            ]
          );
          init = ''
            /set irc.look.server_buffer independent
            /set weechat.look.highlight = "$nick,nix"

            /set weechat.bar.status.items [buffer_count],[buffer_plugin],buffer_number+:+buffer_name+{buffer_nicklist_count}+buffer_filter,[hotlist],completion,scroll,slack_typing_notice
            /set weechat.look.hotlist_names_level 14

            /key bind ctrl-G /go
          '';
        };
    })
  ];
}
