{
  description = "A collection of develop environments";

  outputs = { self }: {
    templates = {
      nix = {
        path = ./nix;
        description = "Nix develop environment";
      };
    };
    defaultTemplate = self.templates.nix;
  };
}
