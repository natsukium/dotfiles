{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem = _: {
    treefmt = {
      projectRootFile = "flake.nix";
      programs = {
        oxfmt.enable = true;
        nixfmt.enable = true;
        # Match nixfmt's width instead of ruff's black-inherited default of 88.
        ruff-format = {
          enable = true;
          lineLength = 100;
        };
        # Keep two-space indentation. treefmt-nix's default leaves it unset,
        # so shfmt falls back to tabs.
        shfmt = {
          enable = true;
          indent_size = 2;
        };
        stylua.enable = true;
        taplo.enable = true;
        terraform.enable = true;
        yamlfmt.enable = true;
      };
    };
  };
}
