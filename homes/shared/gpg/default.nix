{
  programs.gpg = {
    enable = true;
    mutableKeys = false;
    mutableTrust = false;
    publicKeys = [
      {
        source = ./keys.txt;
        trust = "ultimate";
      }
    ];
  };
}
