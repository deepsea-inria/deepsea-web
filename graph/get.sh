#!/bin/bash

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

if [ -n "$hwloc_path"  ]
then
    
# output ligra settings.sh file
(
cat <<EOF
USE_HWLOC=1
HWLOC_PATH=$hwloc_path
HWLOC_INSTALL_PATH=$hwloc_path
EOF
) > ligra/settings.sh

# output Leiserson & Schardl PBFS settings.sh file
(
cat <<EOF
USE_HWLOC=1
HWLOC_PATH=$hwloc_path
HWLOC_INSTALL_PATH=$hwloc_path
EOF
) > ls-pbfs/settings.sh

# output pasl settings.sh file
(
cat <<EOF
USE_HWLOC=1
HWLOC_PATH=$hwloc_path
HWLOC_INSTALL_PATH=$hwloc_path
EOF
) > sc15-graph/graph/bench/settings.sh

fi
