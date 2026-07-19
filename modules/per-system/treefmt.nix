{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem = _: {
    treefmt = {
      projectRootFile = "flake.nix";
      programs = {
        oxfmt.enable = true;
        nixfmt.enable = true;
        shfmt.enable = true;
        stylua.enable = true;
        taplo.enable = true;
        terraform.enable = true;
        yamlfmt.enable = true;
      };
    };
  };
}
