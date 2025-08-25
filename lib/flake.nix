{
  outputs = i: {
    lib = import ./.;
    devshellModule = ./devshellModule.nix;
  };
}
