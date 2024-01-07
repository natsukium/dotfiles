{ pkgs, lib, ... }:
{
  nixpkgs.config = {
    allowUnfree = true;
  };
}
