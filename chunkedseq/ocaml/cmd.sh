PATH=~/pbench:$PATH
ln -s ~/bench/timeout.out timeout.out

opam switch 4.04.0+flambda

eval `opam config env`


#============================================
# LIFO BENCHMARK

# Push 10k items, then repeat n times: push_back (n/r) items
#  followed by pop_back (n/r) items.

make dbg && prun output.dbg -test lifo_debug_1 -seq sized_array,vector,circular_array,ocaml_list,chunked_stack

make opt && prun output.opt -test lifo_1 -seq ocaml_list,vector,chunked_stack,circular_array,sized_array -n 20000000 -length 10,100,1000,10000,100000,1000000,10000000
# -runs 3

pplot -mode scatter -series seq --xlog -x length -y exectime -legend-pos topleft && evince plots.pdf &


#============================================
# OPTIMIZATION LEVEL

make out opt && prun output.out,output.opt -test lifo_1 -seq ocaml_list,vector,chunked_stack,circular_array,sized_array -n 20000000 -length 10000000 -runs 5

pplot -series prog -x seq -y exectime -legend-pos topleft --xtitles-vertical  && evince plots.pdf &


#============================================
# CHUNK SIZE

make opt && prun output.opt -test lifo_1 -seq chunked_stack -n 50000000 -length 10,1000,100000,10000000,50000000 -chunk 32,64,128,256,512,1024
# -runs 3

pplot -mode scatter -series chunk --xlog -x length -y exectime -legend-pos topleft && evince plots.pdf &



#============================================
# GC BENCHMARK

make opt && prun output.opt -test lifo_1 -seq ocaml_list,vector,chunked_stack,circular_array,sized_array -n 20000000 -length 1000000  -static_array_size 2000000 -gc_major 0,1

pplot -series seq -x gc_major -y exectime -legend-pos topright && evince plots.pdf &

pplot -series gc_major -x seq -y exectime -legend-pos topright && evince plots.pdf &


#============================================
# FIFO BENCHMARK

# Push 10k items, then repeat n times: push_back (n/r) items
#  followed by pop_front (n/r) items.

make dbg && prun output.dbg  -test fifo_debug_1 -seq circular_array,ocaml_queue

make opt && prun output.opt -test fifo_1 -seq circular_array,ocaml_queue -n 20000000 -length 10,100,1000,10000,100000,1000000,10000000

pplot -mode scatter -series seq --xlog -x length -y exectime -legend-pos topleft && evince plots.pdf &




