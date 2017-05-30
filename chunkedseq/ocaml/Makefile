
#************************************************************************

# -include settings.sh


#************************************************************************

FILES=\
	Shared \
	TypeSig \
	CapacitySig \
	PSeqSig \
	SeqSig \
	SizedList \
	SizedTwoLists \
	PArray \
	CircularArray \
	Vector \
	PersistentChunk \
	PersistentChunkBytes \
	ChunkedStack \
	ChunkedSeq \
	WeightedChunk \
	PChunkedWeightedSeq \
	PChunkedSeq \
	PChunkedStack \
	Bench



#************************************************************************

SRC=$(FILES:=.ml)

LIBX=str.cmxa unix.cmxa

LIB=str.cma unix.cma


#************************************************************************

all: out

out: output.out
opt: output.opt
dbg: output.dbg


#************************************************************************

output.out: $(SRC)
	ocamlopt $(LIBX) $(SRC) -o output.out

output.dbg: $(SRC)
	ocamlc -g $(LIB) $(SRC) -o output.dbg

output.opt: $(SRC)
	ocamlopt -O2 -unsafe -noassert $(LIBX) $(SRC) -o output.opt

#-inline-max-depth 4 





#************************************************************************

clean:
	rm -f *.cmxa *.out *.opt *.dbg

kill:
	killall -v output.out

benchtools:
	make -C ~/bench all
