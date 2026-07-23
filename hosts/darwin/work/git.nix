{ config, ... }:
let
  workRoot = "${config.home.homeDirectory}/src/work/";
in
{
  programs.git.includes = [
    {
      condition = "gitdir:${workRoot}";
      contents = {
        user = {
          email = config.accounts.email.accounts.work.address;
          # The work GitHub account can only verify signatures made by a key registered
          # to it, so the signing key has to follow the identity, not just the email.
          signingKey = "~/.ssh/id_ed25519_work.pub";
        };
        # Keying HTTPS auth off gitdir rather than the GH_CONFIG_DIR that .envrc
        # exports means git resolves the right account even where direnv never ran —
        # a GUI editor launched from the Dock, a cron job, `git -C` from elsewhere.
        # The envrc export stays, but only to point the `gh` CLI itself at the work
        # config; git no longer depends on it.
        #
        # The empty first entry is load bearing: helper lists are additive, and the
        # first helper to answer wins. Without the reset, the globally configured
        # personal helper stays ahead in the list and silently keeps answering.
        credential."https://github.com".helper = [
          ""
          "!GH_CONFIG_DIR=${config.xdg.configHome}/gh-work gh auth git-credential"
        ];
      };
    }
  ];

  my.programs.ghq."https://github.com/attmcojp".root = workRoot;

  home.file."src/work/.envrc".text = ''
    export GH_CONFIG_DIR=${config.xdg.configHome}/gh-work
  '';

  programs.direnv.config.whitelist.prefix = [ workRoot ];
}
