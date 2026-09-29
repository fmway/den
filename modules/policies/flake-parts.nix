{ den, lib, config, ... }: let
  systemOutputs = builtins.attrNames config.transposition;
  mkOutputPolicy = output: _: [
    (den.lib.policy.route {
      fromClass = output;
      intoClass = "flake-parts";
      collectSubtree = true;
      path = [ output ];
      adaptArgs = { config, ... }: removeAttrs config.allModuleArgs [ "system" ];
    })
  ];
in {
  # Register system output names as classes so aspect keys dispatch correctly.
  den.classes = lib.listToAttrs (
    map (output: {
      name = output;
      value.description = "Flake ${output} output class";
    }) systemOutputs
  );

  # Per-output route policies: class → flake
  den.policies = builtins.listToAttrs (map (output: {
    name = "${output}-to-flake-parts";
    value = mkOutputPolicy output;
  }) systemOutputs);

  den.schema.flake-parts.isEntity = true;
  den.schema.flake-parts.includes =
    den.schema.flake-system.includes ++
    map (output: den.policies."${output}-to-flake-parts") systemOutputs
  ;

  den.schema.flake-parts.excludes = [
    den.policies.system-to-os-outputs
    den.policies.system-to-hm-outputs
  ];
}
