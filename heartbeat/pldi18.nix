# Build script to run the experimental evaluation presented in the
# PLDI'18 paper
#
#   Heartbeat Scheduling: Provable Efficiency for Nested
#   Parallelism
#
# This script is a nixos build script that builds a Docker image. The
# image then replicates the environment used in the experimental
# evaluation of the heartbeat paper.
#
# Build it with:
#
#  nix-build pldi18.nix
#
# Load it with:
#
#  docker load < result
#
# This command should generate a file named `result`.
#
# Load it with:
#
#  docker run --rm -it heartbeat-pldi18

with import <nixpkgs> {};

pkgs.dockerTools.buildImage {

  name = "heartbeat-pldi18";

  contents = [
    pkgs.bash
    pkgs.gcc6
    pkgs.ocaml
    pkgs.gperftools
    pkgs.ipfs
    pkgs.hwloc
#    pkgs.R
#    pkgs.texlive.combined.scheme-small
  ];

  config = { Cmd = [ "/bin/bash" ]; };
  
}
