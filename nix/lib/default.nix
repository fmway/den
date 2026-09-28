{
  lib,
  config,
  inputs,
  ...
}:
let
  inherit (config) den;
  load =
    f:
    import f {
      inherit
        lib
        config
        inputs
        den
        den-lib
        ;
    };
  registry = builtins.mapAttrs (_: load) {
    aspects = ./aspects;
    canTake = ./can-take.nix;
    __findFile = ./den-brackets.nix;
    forward = ./forward.nix;
    home-env = ./home-env.nix;
    nh = ./nh.nix;
    nixModule = ../nixModule;
    nsTypes = ./namespace-types.nix;
    parametric = ./parametric.nix;
    pipes = ./pipes.nix;
    take = ./take.nix;
    policy = ./policy-effects.nix;
    resolveEntity = ./resolve-entity.nix;
    strict = ./strict.nix;
    capture = ./diag/capture.nix;
    policyInspect = ./policy-inspect.nix;
    schemaUtil = ./schema-util.nix;
    synthesizePolicies = ./synthesize-policies.nix;
    fx = ./fx.nix;
    schema = ./schema.nix;
  };
  den-lib = registry // {
    # One shared full resolve of the flake entity (the fleet root). The flake
    # output wiring reads its imports and den.lib.pipes reads its assembled
    # quirk pools — one pipeline run stands behind both, so reading a quirk
    # from a flake output never re-resolves the fleet.
    fleetResult = registry.aspects.resolveWithPaths "flake" (registry.resolveEntity "flake" { });
  };
in
den-lib
