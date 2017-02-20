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

CMDLINEPARAM=1     #  Expect at least command-line parameter.
if [ $# -ge $CMDLINEPARAM ]
then
    hwloc_path=#1  #  If more than one command-line param,
                   #+ then just take the first.
else
    hwloc_path=/usr/lib64/pkgconfig/
fi


# output ligra settings.sh file
(
cat <<EOF
QUICKCHECK_PATH=../quickcheck
HWLOC_PATH=$hwloc_path
HWLOC_INSTALL_PATH=$hwloc_path
EOF
) > ligra/settings.sh

# output Leiserson & Schardl PBFS settings.sh file
(
cat <<EOF
QUICKCHECK_PATH=../quickcheck
HWLOC_PATH=$hwloc_path
HWLOC_INSTALL_PATH=$hwloc_path
EOF
) > ls-pbfs/settings.sh

# output pasl settings.sh file
(
cat <<EOF
QUICKCHECK_PATH=../../../quickcheck
HWLOC_PATH=$hwloc_path
HWLOC_INSTALL_PATH=$hwloc_path
EOF
) > sc15-graph/graph/bench/settings.sh



