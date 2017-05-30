PATH=~/pbench:$PATH
ln -s ~/bench/timeout.out timeout.out

opam switch 4.04.0+flambda

eval `opam config env`


#============================================
# EPHEMERAL LIFO BENCHMARK

# Push 10k items, then repeat n times: push_back (n/r) items
#  followed by pop_back (n/r) items.

make opt && prun output.opt -test real_lifo -seq ocaml_list,vector,chunked_stack_256,circular_array_big,sized_array_big,sized_array -n 20000000 -length 100,1000,10000,100000,1000000,10000000 -runs 3

cp plots.pdf plots/plots_lifo.pdf && cp results.txt plots/results_lifo.txt

pplot -mode scatter -series seq --xlog -x length -y exectime --yzero -legend-pos topleft && evince plots.pdf &



#============================================
# EPHEMERAL CHUNK_STACK BEST CHUNK SIZE

make opt && prun output.opt -test real_lifo -seq chunked_stack -n 50000000 -length 10,1000,100000,10000000,20000000 -chunk 32,64,128,256,512,1024 -runs 3

# 10,100,1000,10000,100000,1000000,10000000,20000000
##==> todo: investigate issue with outofbound.

cp plots.pdf plots/plots_chunk_size.pdf && cp results.txt plots/results_chunk_size.txt

pplot -mode scatter -series chunk --xlog -x length -y exectime --yzero -legend-pos topleft && evince plots.pdf &



#============================================
# PERSISTENT LIFO BENCHMARK

# smaller sizes, all structures:
make opt && prun output.opt -test real_lifo -seq ocaml_list,pchunked_seq,pchunked_stack_copy_on_write,pchunked_stack_persistence -n 2000000 -length 10,100,1000,10000,100000,1000000

# full sizes, only fast structures:
make opt && prun output.opt -test real_lifo -seq sized_array,ocaml_list,pchunked_stack_persistence -n 20000000 -length 100,1000,10000,100000,1000000,10000000 -runs 3

cp plots.pdf plots/plots_plifo.pdf && cp results.txt plots/results_plifo.txt

pplot -mode scatter -series seq --xlog -x length -y exectime --yzero -legend-pos topleft && evince plots.pdf &


#============================================
# PERSISTENT BEST CHUNK SIZE

make opt && prun output.opt -test real_lifo -seq pchunked_stack_copy_on_write,pchunked_stack_persistence -n 10000000 -length 10,1000,100000,10000000,20000000 -chunk 8,16,32,64 && prun output.opt -test real_lifo -seq pchunked_stack_persistence -n 10000000 -length 10,1000,100000,10000000,20000000 -chunk 128,256,512 --append


# -runs 3

##==> todo: investigate issue with outofbound.

cp plots.pdf plots/plots_chunk_size.pdf && cp results.txt plots/results_chunk_size.txt

pplot -mode scatter -series chunk --xlog -x length -y exectime --yzero -legend-pos topleft && evince plots.pdf &







#============================================
# EPHEMERAL FIFO BENCHMARK

# Push 10k items, then repeat n times: push_back (n/r) items
#  followed by pop_front (n/r) items.


make opt && prun output.opt -test real_fifo -seq circular_array,ocaml_queue -n 20000000 -length 10,100,1000,10000,100000,1000000,10000000

pplot -mode scatter -series seq --xlog -x length -y exectime --yzero -legend-pos topleft && evince plots.pdf &




#============================================
#============================================

#============================================
# EFFECT OF HARD-CODING CHUNK SIZE

make opt && prun output.opt -test real_lifo -seq chunked_stack,chunked_stack_256 -n 20000000 -length 10,100,1000,10000,100000,1000000,10000000 -runs 3

pplot -mode scatter -series seq --yzero --xlog -x length -y exectime -legend-pos topleft && evince plots.pdf &


#============================================
# GC-MAJOR EFFECT

make opt && prun output.opt -test lifo_1 -seq ocaml_list,vector,chunked_stack,circular_array,sized_array -n 20000000 -length 1000000  -static_array_size 2000000 -gc_major 0,1 -runs 3

pplot -series seq -x gc_major -y exectime -legend-pos topright && evince plots.pdf &

pplot -series gc_major -x seq -y exectime -legend-pos topright && evince plots.pdf &


#============================================
# LIFO_1 vs REAL_LIFO

make opt && prun output.opt -test real_lifo,lifo_1 -seq ocaml_list,vector,chunked_stack,circular_array,sized_array -n 20000000 -length 10,100,1000,10000,100000,1000000,10000000 -runs 3

pplot -mode scatter -series test -chart seq --yzero --xlog -x length -y exectime -legend-pos topleft && evince plots.pdf &


#============================================
# COMPILER OPTIMIZATION LEVEL EFFECT

make out opt && prun output.out,output.opt -test lifo_1 -seq ocaml_list,vector,chunked_stack,circular_array,sized_array -n 20000000 -length 10000000 -runs 5

pplot -series prog -x seq -y exectime -legend-pos topleft --xtitles-vertical  && evince plots.pdf &


#============================================
#============================================
# UNIT TESTING OF STRUCTURES

make dbg && prun output.dbg  -test fifo_debug_1 -seq circular_array,ocaml_queue

make dbg && prun output.dbg -test lifo_debug_1 -seq sized_array,vector,circular_array,ocaml_list,chunked_stack

make dbg && prun output.dbg -test lifo_debug_1 -seq ocaml_list,parray,persistent_chunk,pchunked_seq,pchunked_stack_copy_on_write,pchunked_stack_persistence

# e.g.
   output.dbg -test lifo_debug_1 -seq pchunked_seq -debug 1



