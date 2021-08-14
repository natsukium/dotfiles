{
  description = "A collection of develop environments";

  outputs = { self }: {
    templates = {
      nix = {
        path = ./nix;
        description = "Nix develop environment";
      };
      python = {
        path = ./python;
        description = "Python develop environment";
      };
      nodejs = {
        path = ./nodejs;
        description = "NodeJS develop environment";
      };
    };
    defaultTemplate = self.templates.nix;
  };
}
