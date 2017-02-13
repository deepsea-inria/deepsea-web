#!/bin/bash

# quickcheck
ipfs daemon & # need to start the ipfs daemon
ipfs_pid=$!
sleep 20  # pause is required
ipfs get QmUvGoyv8hBprTqjFnhD5m4HGkcxqS4FoNteKEbYmyLj9n -o=quickcheck
kill $ipfs_pid
# chunkedseq
git clone https://github.com/deepsea-inria/chunkedseq.git
# pbench
git clone https://github.com/deepsea-inria/pbench.git
# ligra
git clone https://github.com/deepsea-inria/ligra.git
# Leiserson & Schardl PBFS
git clone https://github.com/deepsea-inria/ls-pbfs.git
# PDFS15 sources
git clone https://github.com/deepsea-inria/pasl.git -b new-sc15-graph sc15-graph
