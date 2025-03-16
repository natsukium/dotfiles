{ config, ... }:
{
  programs.gh-dash = {
    enable = true;
    settings = {
      prSections = [
        {
          title = "My Pull Requests";
          filters = "is:open author:@me";
          layout.author.hidden = true;
        }
        {
          title = "Needs My Review";
          filters = "is:open review-requested:@me";
        }
        {
          title = "Involved";
          filters = "is:open involves:@me -author:@me";
        }
        {
          title = "Nixpkgs Approved r-ryantm";
          filters = ''repo:NixOS/nixpkgs is:pr is:open author:r-ryantm label:"12.approved-by: package-maintainer"'';
          layout = {
            author.hidden = true;
            repo.hidden = true;
          };
        }
        {
          title = "Nixpkgs Python";
          filters = ''repo:NixOS/nixpkgs is:pr is:open label:"6.topic: python"'';
          layout.repo.hidden = true;
        }
      ];
      pager.diff = if config.programs.git.delta.enable then "delta" else "less";
      keybindings = {
        prs = [
          {
            key = "O";
            command = ''
              nvr -c ":Octo pr edit {{.PrNumber}}"
            '';
          }
        ];
      };
      repoPaths =
        let
          basePath = "${config.programs.git.extraConfig.ghq.root}/github.com";
        in
        {
          "NixOS/nixpkgs" = "${basePath}/natsukium/nixpkgs";
        };
    };
  };
}
