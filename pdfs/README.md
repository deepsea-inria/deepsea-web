To build this package, first download the [nix package
manager](https://nixos.org/nix/download.html) and then run the
following on the command line:

$ nix-shell -p "haskellPackages.ghcWithPackages (pkgs: with pkgs; [pandoc-types pandoc-citeproc])"

From the nix shell, run

$ make

and then look for the `html` and `pdf` file outputs.