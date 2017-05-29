
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
	ChunkedStack \
	ChunkedSeq



#	MeasuredType \#
#	InhabType \
#	Size \
#	Reducer \
#	PureSeq \
#	ImpSeq \
#	PureMeasuredSeq \
#	MyStream \
#	CircularArray \
#	BankersDeque \
#	BatchedQueue \
#	SizedList \
#	SizedListRec \
#	FingerTree \
#	FingerTreeLazy \
#	FingerTreeNbInlined \
#	FingerTreeNb \
#	FingerTreeIndirect \
#	FFTreeBufferCopy \
#	FFTreeBufferMove \
#	FFTreeBufferMoveInlined \
#	FFTreeList \


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

output.opt: $(SRC)
	ocamlopt -unsafe -noassert $(LIBX) $(SRC) -o output.opt

output.dbg: $(SRC)
	ocamlc -g $(LIB) $(SRC) -o output.dbg


#************************************************************************

clean:
	rm -f *.cmxa *.out *.opt *.dbg

kill:
	killall -v output.out

benchtools:
	make -C ../benchtools all