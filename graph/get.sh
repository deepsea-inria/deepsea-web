#!/bin/bash

# quickcheck
ipfs get QmUvGoyv8hBprTqjFnhD5m4HGkcxqS4FoNteKEbYmyLj9n -o=quickcheck
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
