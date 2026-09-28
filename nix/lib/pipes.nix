# Class-independent access to assembled quirk (pipe) data.
#
# The pipeline collects quirk emits class-agnostically and assembles them into
# per-scope contexts (scope ctx // quirk pools). A class module normally
# receives a pool as a function argument; callers OUTSIDE evalModules — flake
# outputs, tooling, reports — read the same assembled pools here instead of
# registering a throwaway class purely to read them back.
{
  den,
  lib,
  ...
}:
let
  inherit (den.lib) fleetResult;

  pipeContexts = fleetResult.pipeContexts;
  quirks = den.quirks or { };

  knownScopes =
    let
      names = builtins.attrNames pipeContexts;
      shown = lib.take 10 names;
    in
    builtins.concatStringsSep ", " shown
    + lib.optionalString (builtins.length names > 10) ", … (${toString (builtins.length names)} total)";

  # A `{ pkgs, ... }:` emit is a config thunk: it resolves only inside
  # evalModules, against the producing class's config. Handing the marker
  # record to a plain list consumer would pass it off as data.
  assertResolved =
    scope: quirk: values:
    let
      thunks = builtins.filter (v: builtins.isAttrs v && v ? __configThunk) values;
    in
    if thunks == [ ] then
      values
    else
      throw ''
        den: den.lib.pipes: quirk `${quirk}` at scope `${scope}` holds ${toString (builtins.length thunks)} config-dependent value(s) (`{ pkgs, ... }:` emits) which only resolve inside evalModules — consume this quirk from a class module instead.
      '';

  collectWith =
    {
      quirk,
      scope ? fleetResult.rootScopeId,
    }:
    if !(quirks ? ${quirk}) then
      throw "den: den.lib.pipes: no quirk `${quirk}` in den.quirks — declared: ${
        if quirks == { } then "<none>" else builtins.concatStringsSep ", " (builtins.attrNames quirks)
      }"
    else if !(pipeContexts ? ${scope}) then
      throw "den: den.lib.pipes: no scope `${scope}` in the flake resolve — known scopes: ${knownScopes}"
    else
      assertResolved scope quirk (pipeContexts.${scope}.${quirk} or [ ]);
in
{
  # Assembled pool at the flake root scope — the scope a fleet-wide read lands
  # on. Emits from deeper scopes reach it through pipe.expose / pipe.collectAll.
  collect = quirk: collectWith { inherit quirk; };

  inherit collectWith;

  # Raw per-scope contexts (scope ctx // quirk pools), for callers that want to
  # address a scope themselves. May carry pipeline markers (__pipeTargeted,
  # __pipeConfigThunks) beside the quirk keys.
  contexts = pipeContexts;

  scopes = builtins.attrNames pipeContexts;

  rootScopeId = fleetResult.rootScopeId;
}
