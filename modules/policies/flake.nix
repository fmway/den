# Flake output policies — activated via schema includes.
{ den, lib, ... }: let
  inherit (den.lib.policy) resolve;
in {
  # flake → flake-system: fan out per system
  den.policies.flake-to-systems =
    _: map (system: resolve.to "flake-system" { inherit system; }) den.systems;

  # flake-system → host: resolve OS outputs
  den.policies.system-to-os-outputs =
    { system, ... }:
    let
      hosts = den.hosts.${system} or { };
    in
    lib.concatMap (
      host:
      lib.optionals (host.intoAttr != [ ]) [
        (resolve.to "host" { inherit host; })
        (den.lib.policy.instantiate host)
      ]
    ) (builtins.attrValues hosts);

  # flake-system → home: resolve HM outputs
  den.policies.system-to-hm-outputs =
    { system, ... }:
    let
      homes = den.homes.${system} or { };
    in
    lib.concatMap (
      home:
      lib.optionals (home.intoAttr != [ ]) [
        (resolve.to "home" { inherit home; })
        (den.lib.policy.instantiate home)
      ]
    ) (builtins.attrValues homes);

  den.schema.flake.includes = [ den.policies.flake-to-systems ];
  den.schema.flake-system.includes = [
    den.policies.system-to-os-outputs
    den.policies.system-to-hm-outputs
  ];
}
