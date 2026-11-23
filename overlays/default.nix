# This file is auto-generated from configuration.org.
# Do not edit directly.

{ inputs }:
{
  stable = final: prev: {
  };

  cuda =
    final: prev:
    prev.lib.optionalAttrs (prev.config.cudaSupport or false) (
      let
        pkgsWithCuda = import inputs.nixpkgs-cuda {
          inherit (prev.stdenv.hostPlatform) system;
          config = {
            cudaSupport = true;
            allowUnfree = true;
          };
        };
        pkgs = import inputs.nixpkgs {
          inherit (prev.stdenv.hostPlatform) system;
          config.allowUnfree = true;
        };
      in
      {
        inherit (pkgsWithCuda) ollama;
        inherit (pkgs) onnxruntime;
        handy = prev.handy.override {
          inherit (pkgsWithCuda) onnxruntime;
        };
        calibre = pkgs.calibre;
      }
    );

  temporary-fix = final: prev: {
    toybox = prev.toybox.overrideAttrs (
      old:
      prev.lib.optionalAttrs prev.stdenv.hostPlatform.isDarwin {
        preBuild = (old.preBuild or "") + ''
          sed -i 's/^CONFIG_READAHEAD=y$/# CONFIG_READAHEAD is not set/' .config
        '';
      }
    );
    vimPlugins =
      let
        testsFail = prev.stdenv.hostPlatform.isDarwin || prev.stdenv.hostPlatform.system == "aarch64-linux";
      in
      prev.vimPlugins
      // prev.lib.optionalAttrs testsFail {
        rustaceanvim = final.neovimUtils.buildNeovimPlugin {
          luaAttr = final.neovim-unwrapped.lua.pkgs.rustaceanvim.overrideAttrs { doCheck = false; };
        };
      };
  };

  pre-release = final: prev: { };

  patches = final: prev: {
    gh-dash =
      (final.writeShellApplication {
        name = "gh-dash";
        text = ''
          LANG=C.UTF-8 ${final.lib.getExe prev.gh-dash} "$@"
        '';
      }).overrideAttrs
        { pname = "gh-dash"; };
    inherit (final.callPackage ../pkgs/mkShim { }) mkShim commandLineToolsShim;
  };
}
