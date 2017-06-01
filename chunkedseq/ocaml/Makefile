
#************************************************************************

# -include settings.sh


#************************************************************************

INCS=\
	Shared \
	TypeSig \
	CapacitySig \
	PSeqSig \
	SeqSig \
	PList \
	SizedList \
	SizedTwoLists \
	PChunkArray \
	ChunkBytesBuffer \
	StackArray \
	CircularArray \
	Vector \
	PChunkCirc \
	PChunkStack \
	PChunkBytesBuffer \
	PChunkBytesCirc \
	ChunkedStack \
	ChunkedSeq \
	ChunkedString \
	WeightedChunk \
	PChunkedWeightedSeq \
	PChunkedSeq \
	PChunkedStack \
	PChunkedString

FILES=$(INCS) Bench



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
	rm -f *.cmxa output.out *.opt *.dbg *.cmx

kill:
	killall -v output.out

benchtools:
	make -C ~/bench all


#************************************************************************

# packed.opt: Shared.ml StackPacked.ml
# 	ocamlopt -O2  $(LIBX) Shared.ml StackPacked.ml -o packed.opt
# StackArray.ml 

packed.opt: $(INCS:=.ml) StackPacked.ml
	ocamlopt -O2  $(LIBX) $(INCS:=.ml) StackPacked.ml -o packed.opt


# -unsafe -noassert