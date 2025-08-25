{inputs, ...}: let
  inherit (inputs) pkgs ntlib soonix;
in {
  tests = ntlib.mkNixtest {
    modules = ntlib.autodiscover {dir = "${inputs.self}/tests";};
    args = {
      inherit ntlib soonix pkgs;
    };
  };
}
