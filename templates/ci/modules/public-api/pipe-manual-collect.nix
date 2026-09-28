# Manual, class-independent quirk collection: den.lib.pipes reads the assembled
# pools the pipeline already computed — no throwaway class to read them back.
{ denTest, lib, ... }:
{
  flake.tests.pipe-manual-collect = {

    # A root-scope emit read back through den.lib.pipes, with no class
    # registered anywhere. collectWith with the default scope is the same read.
    test-collect-root-emit = denTest (
      { den, ... }:
      {
        den.quirks.inputs.description = "Input declarations";
        den.aspects.root-inputs.inputs = {
          source = "root";
        };
        den.schema.flake.includes = [ den.aspects.root-inputs ];

        expr = {
          viaCollect = den.lib.pipes.collect "inputs";
          viaCollectWith = den.lib.pipes.collectWith { quirk = "inputs"; };
        };
        expected = {
          viaCollect = [ { source = "root"; } ];
          viaCollectWith = [ { source = "root"; } ];
        };
      }
    );

    # Declared but never emitted: an empty pool, not an error.
    test-collect-empty = denTest (
      { den, ... }:
      {
        den.quirks.inputs.description = "Input declarations";

        expr = den.lib.pipes.collect "inputs";
        expected = [ ];
      }
    );

    # A typo in the quirk name fails loudly instead of reading as empty.
    test-collect-unknown-quirk = denTest (
      { den, ... }:
      {
        den.quirks.inputs.description = "Input declarations";

        expr = den.lib.pipes.collect "nope";
        expectedError = {
          type = "ThrownError";
          msg = "den: den.lib.pipes: no quirk `nope` in den.quirks";
        };
      }
    );

    # Emission is scope-local: a host emit stays at the host scope until a pipe
    # policy routes it. collectAll at the flake root pulls it fleet-wide.
    test-collect-pulls-host-emits = denTest (
      { den, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.quirks.inputs.description = "Input declarations";

        den.aspects.igloo.inputs = {
          source = "host";
        };

        den.policies.inputs-to-root =
          _:
          let
            inherit (den.lib.policy) pipe;
          in
          [ (pipe.from "inputs" [ (pipe.collectAll ({ host, ... }: true)) ]) ];
        den.schema.flake.includes = [ den.policies.inputs-to-root ];

        expr = den.lib.pipes.collect "inputs";
        expected = [ { source = "host"; } ];
      }
    );

    # The same pool through both consumers in one evaluation: a class module
    # arg at the host scope and den.lib.pipes at the flake root. The old
    # manual pattern (seeding the pool back through constantHandler) recursed
    # on exactly this read.
    test-collect-coexists-with-class-consumer = denTest (
      { den, igloo, ... }:
      {
        den.hosts.x86_64-linux.igloo.users.tux = { };
        den.quirks.inputs.description = "Input declarations";

        den.aspects.igloo.inputs = {
          port = 80;
        };

        den.aspects.consumer.nixos =
          { inputs, ... }:
          {
            networking.hostName = toString (builtins.head inputs).port;
          };
        den.aspects.igloo.includes = [ den.aspects.consumer ];

        den.policies.inputs-to-root =
          _:
          let
            inherit (den.lib.policy) pipe;
          in
          [ (pipe.from "inputs" [ (pipe.collectAll ({ host, ... }: true)) ]) ];
        den.schema.flake.includes = [ den.policies.inputs-to-root ];

        expr = {
          viaClass = igloo.networking.hostName;
          viaLib = den.lib.pipes.collect "inputs";
        };
        expected = {
          viaClass = "80";
          viaLib = [ { port = 80; } ];
        };
      }
    );

    # The flake-output shape this API exists for: an output reads the pool
    # directly, with no class and no second fleet resolve.
    test-collect-flake-output = denTest (
      { den, config, ... }:
      {
        den.quirks.inputs.description = "Input declarations";
        den.aspects.root-inputs.inputs = {
          source = "root";
        };
        den.schema.flake.includes = [ den.aspects.root-inputs ];

        flake.custom-inputs = den.lib.pipes.collect "inputs";

        expr = config.flake.custom-inputs;
        expected = [ { source = "root"; } ];
      }
    );
  };
}
