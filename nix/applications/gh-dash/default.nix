{
  pkgs,
  config,
  ...
}: {
  programs.gh-dash = {
    enable = true;

    # preview pane is corrupted when `LANG=ja_JP.UTF-8`
    # https://github.com/dlvhdr/gh-dash/issues/316
    package = pkgs.gh-dash.overrideAttrs (oldAttrs: {
      nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [pkgs.makeWrapper];
      postFixup =
        (oldAttrs.postFixup or "")
        + ''
          wrapProgram $out/bin/gh-dash --set LANG C.UTF-8
        '';
    });

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
          filters = "repo:NixOS/nixpkgs is:pr is:open author:r-ryantm label:\"12.approved-by: package-maintainer\"";
          layout = {
            author.hidden = true;
            repo.hidden = true;
          };
        }
        {
          title = "Nixpkgs Python";
          filters = "repo:NixOS/nixpkgs is:pr is:open label:\"6.topic: python\"";
          layout.repo.hidden = true;
        }
      ];
      pager.diff =
        if config.programs.git.delta.enable
        then "delta"
        else "less";
    };
  };
}
