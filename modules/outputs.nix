{ den, lib, ... }:
{
  systems = den.systems;
  # Avoid additional evalModules
  flake = lib.mkMerge (builtins.concatMap (x: map (x: x.config.flake or x.flake or {}) (x.imports or [] ++ [(removeAttrs x [ "imports" ])])) den.lib.fleetResult.imports);

  perSystem = { system, ... }:
  {
    imports = [
      (den.lib.aspects.resolve "flake-parts" (den.lib.resolveEntity "flake-parts" { inherit system; }))
    ];
  };
}
