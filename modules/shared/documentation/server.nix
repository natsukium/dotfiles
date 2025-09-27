{ lib, ... }:

let
  inherit (lib) mkDefault;
in
{
  documentation = {
    enable = mkDefault false;
    doc.enable = mkDefault false;
    info.enable = mkDefault false;
    man.enable = mkDefault false;
  };
}
