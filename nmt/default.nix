{ modules, testedAttrPath, tests, pkgs, lib ? pkgs.lib }:

with lib;

let

  evalTest = name: test:
    evalModules {
      modules = let
        initModule = { config, ... }: {
          nmt.name = name;
          nmt.tested = getAttrFromPath testedAttrPath config;
        };
      in [ initModule ./nmt.nix test ] ++ modules;
    };

  evaluatedTests = mapAttrs evalTest tests;

  scriptPath = makeBinPath (with pkgs; [
    coreutils
    ncurses # For tput.
  ]);

  runScript = name: script:
    runShellOnlyCommand name ''
      set -uo pipefail

      export PATH="${scriptPath}"

      . "${./bash-lib/color-echo.sh}"

      ${script}

      exit 0
    '';

  runShellOnlyCommand = name: shellHook:
    pkgs.runCommandLocal name { inherit shellHook; } ''
      echo This derivation is only useful when run through nix-shell.
      exit 1
    '';

  reportResult = { name, result, onSuccess, onError }:
    if result.success then ''
      noteEcho "${name}: OK"
      ${onSuccess}
    '' else ''
      errorEcho "${name}: FAILED"
      cat "${result.report}/output"
      echo "For further reference please introspect ${result.report}"
      ${onError}
    '';

  buildTest = name: test: test.config.nmt.result.build;

  buildAllTests = pkgs.linkFarm "nmt-all-tests" (mapAttrsToList (n: v: {
    name = n;
    path = buildTest n v;
  }) evaluatedTests);

  runTest = name: test:
    runScript "nmt-run-${name}" (reportResult {
      inherit (test.config.nmt) name result;
      onSuccess = "exit 0";
      onError = "exit 1";
    });

  runAllTests = runScript "nmt-run-all-tests" (concatStringsSep "\n\n"
    (mapAttrsToList (n: test:
      let evaluated = evalTest n test;
      in reportResult {
        inherit (evaluated.config.nmt) name result;
        onSuccess = "";
        onError = "ERR=1";
      }) tests) + ''
        if [[ -v ERR ]]; then
          exit 1
        else
          exit 0
        fi
      '');

in rec {
  build = mapAttrs buildTest evaluatedTests // { all = buildAllTests; };

  run = mapAttrs runTest evaluatedTests // { all = runAllTests; };

  report = mapAttrs (name: test: test.config.nmt.result.report) evaluatedTests;

  list = runScript "nmt-list-tests" (let
    scripts = concatStringsSep "\n" (map (n: "echo ${n}") (attrNames tests));
  in ''
    echo all
    ${scripts}
  '');
}
