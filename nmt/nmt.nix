{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.nmt;

  testScript = let
    scriptPath =
      makeBinPath (with pkgs; [ coreutils diffutils findutils gnugrep gnused ]);
  in ''
    set -uo pipefail

    export PATH="${scriptPath}"

    . "${./bash-lib/assertions.sh}"

    TESTED="${cfg.tested}"
    ${cfg.script}
  '';

in {
  options.nmt = {
    name = mkOption {
      type = types.str;
      internal = true;
      readOnly = true;
      description = "Name of test case.";
    };

    description = mkOption {
      type = types.str;
      default = "";
      description = "Optional description of this test case.";
    };

    script = mkOption {
      type = types.lines;
      example = ''
        assertFileExists home-files/.Xresources
      '';
      description = "Test script.";
    };

    tested = mkOption {
      type = types.package;
      readOnly = true;
      description = ''
        The tested module result package.
      '';
    };

    result = {
      success = mkOption {
        type = types.bool;
        internal = true;
        readOnly = true;
        description = ''
          Whether the test succeeded.
        '';
      };

      build = mkOption {
        type = types.package;
        internal = true;
        readOnly = true;
        description = ''
          The test build. On test failure, the build will fail and no output
          generated. On test success, the build will succeed and produce an
          output directory containing the tested directory and the generated
          test script.
        '';
      };

      report = mkOption {
        type = types.package;
        internal = true;
        readOnly = true;
        description = ''
          The test results.
        '';
      };
    };
  };

  config = {
    nmt.result = {
      success = ''
        OK
      '' == builtins.readFile "${cfg.result.report}/result";

      build = pkgs.runCommandLocal "nmt-test-${cfg.name}" {
        inherit testScript;
        passAsFile = [ "testScript" ];
      } ''
        mkdir -p $out
        ln -s ${cfg.tested} $out/tested
        install -m755 $testScriptPath $out/script

        . $testScriptPath
      '';

      report = pkgs.runCommandLocal "nmt-report-${cfg.name}" {
        inherit testScript;
        passAsFile = [ "testScript" ];
      } ''
        mkdir -p $out
        ln -s ${cfg.tested} $out/tested
        install -m755 $testScriptPath $out/script

        if bash $testScriptPath 2>&1 > $out/output; then
          echo OK > $out/result
        else
          echo FAILED > $out/result
        fi
      '';
    };
  };
}
