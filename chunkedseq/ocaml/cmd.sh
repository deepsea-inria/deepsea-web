PATH=~/pbench:$PATH
ln -s ~/pbench/timeout.out timeout.out

opam switch 4.04.0+flambda

eval `opam config env`



#============================================
# LIFO BENCHMARKS : EPHEMERAL + PERSISTENT STACKS

# Push 10k items, then repeat n times: push_back (n/r) items
#  followed by pop_back (n/r) items.

make opt && prun output.opt -test real_lifo -seq list_ref,vector,stack_packed_ref_256,chunked_stack_256,stack_array -n 20000000 -length 100,1000,10000,100000,1000000,10000000 -runs 5

# pchunked_stack_ref_256 bug to fix
# output.opt -test real_lifo -seq pchunked_stack_ref_256 -n 20000000 -length 10000000


pplot -mode scatter -series seq --xlog -x length -y exectime --yzero -legend-pos topleft && evince plots.pdf &

cp plots.pdf plots/plots_lifo.pdf && cp results.txt plots/results_lifo.txt

  # vectors have regular behavior on powers of two
  # make opt && prun output.opt -test real_lifo -seq vector -n 16777216 -length 128,1024,4096,65536,262144,1048576,4194304,8388608 -runs 3

  # circular_array_big,stack_array_big

# on small sizes

make opt && prun output.opt -test real_lifo -seq list_ref,vector,stack_packed_ref_256,chunked_stack_256,stack_array -n 10000000 -length 1,2,5,10,20,50,100,200,500,1000,100,1000,10000,100000,1000000,10000000

make opt && prun output.opt -test real_lifo -seq list_ref,vector,stack_packed_ref_256,chunked_stack_256,stack_array -n 50000000 -length 1,2,5,10,20,50,100,200,500,1000,100,1000,10000,100000,1000000,10000000,50000000


#============================================
# STRING BUFFER BENCHMARK

make opt && prun output.opt -test real_string_buffer -seq stdlib_buffer,pchunked_string_4096,chunked_string_4096 -n 1000000000 -max_word_length 10,20,50,500,5000 -length 1000000000 -runs 5

pplot -mode bar -chart length -series seq -x max_word_length -y exectime --xtitles-vertical --yzero -legend-pos topright && evince plots.pdf &

cp plots.pdf plots/plots_buffer.pdf && cp results.txt plots/results_buffer.txt


# more data

  make opt && prun output.opt -test real_string_buffer -seq stdlib_buffer,pchunked_string_4096 -n 500000000 -max_word_length 20,50,500,5000,50000 -length 10000,100000,1000000,10000000,500000000 -runs 3

  pplot -chart max_word_length -mode scatter -series seq --xlog -x length -y exectime --yzero -legend-pos bottomright && evince plots.pdf &



#============================================
# ARRAY OF BUCKETS BENCHMARK

make opt && prun output.opt -test real_test_buckets -seq list,stack_packed_256 -n 10000000 -nb_buckets 1,10,100,1000,10000,100000,1000000,10000000 -runs 1

  # -more buckets: ,30000000,50000000,100000000

pplot -mode scatter -series seq --xlog -x nb_buckets -y exectime --yzero -legend-pos topleft && evince plots.pdf &

  # used for single bucket comparison
  # chunked_stack_256,chunked_stack_256_indirect


#============================================
# RANDOM ACCESS

make opt && prun output.opt -test real_random_access -n 200000000 -length 10000000 -seq vector,chunked_stack_256



#============================================
#============================================
#============================================


#============================================
# EPHEMERAL CHUNK_STACK BEST CHUNK SIZE

# big sizes
make opt && prun output.opt -test real_lifo -seq chunked_stack -n 50000000 -length 10,1000,100000,10000000,20000000 -chunk 512,1024,2048,4096

# small sizes
make opt && prun output.opt -test real_lifo -seq chunked_stack -n 50000000 -length 10,1000,100000,10000000,20000000 -chunk 32,64,128,256,512,1024 -runs 3

# 10,100,1000,10000,100000,1000000,10000000,20000000
##==> todo: investigate issue with outofbound.

pplot -mode scatter -series chunk --xlog -x length -y exectime --yzero -legend-pos topleft && evince plots.pdf &

cp plots.pdf plots/plots_chunk_size.pdf && cp results.txt plots/results_chunk_size.txt


#============================================
# PERSISTENT BEST CHUNK SIZE

make opt && prun output.opt -test real_lifo -seq pchunked_stack_copy_on_write_ref,pchunked_stack_ref -n 10000000 -length 10,1000,100000,10000000 -chunk 8,16,32,64 && prun output.opt -test real_lifo -seq pchunked_stack_ref -n 10000000 -length 10,1000,100000,10000000 -chunk 128,256,512 --append

# -runs 3

pplot -mode scatter -chart seq -series chunk --xlog -x length -y exectime --yzero -legend-pos topleft && evince plots.pdf &

cp plots.pdf plots/plots_pchunk_size.pdf && cp results.txt plots/results_pchunk_size.txt


#============================================
# STRING BUFFER BEST CHUNK SIZE

make opt && prun output.opt -test real_string_buffer -seq pchunked_string -n 200000000 -length 50,500,5000,50000 -chunk 1024,2048,4096,8192 -runs 3

pplot -mode scatter -chart seq -series chunk --xlog -x length -y exectime --yzero -legend-pos bottomleft && evince plots.pdf &

cp plots.pdf plots/plots_pbchunk_size.pdf && cp results.txt plots/results_pbchunk_size.txt



#============================================
# EFFECT OF HARD-CODING CHUNK SIZE

make opt && prun output.opt -test real_lifo -seq chunked_stack,chunked_stack_256 -n 20000000 -length 10,100,1000,10000,100000,1000000,10000000 -runs 3

pplot -mode scatter -series seq --yzero --xlog -x length -y exectime -legend-pos topleft && evince plots.pdf &


#============================================
# GC-MAJOR EFFECT

make opt && prun output.opt -test lifo_1 -seq list_ref,vector,chunked_stack,circular_array,stack_array -n 20000000 -length 1000000  -static_array_size 2000000 -gc_major 0,1 -runs 3

pplot -series seq -x gc_major -y exectime -legend-pos topright && evince plots.pdf &

pplot -series gc_major -x seq -y exectime -legend-pos topright && evince plots.pdf &


#============================================
# LIFO_1 vs REAL_LIFO

make opt && prun output.opt -test real_lifo,lifo_1 -seq list_ref,vector,chunked_stack,circular_array,stack_array -n 20000000 -length 10,100,1000,10000,100000,1000000,10000000 -runs 3

pplot -mode scatter -series test -chart seq --yzero --xlog -x length -y exectime -legend-pos topleft && evince plots.pdf &


#============================================
# COMPILER OPTIMIZATION LEVEL EFFECT

make out opt && prun output.out,output.opt -test lifo_1 -seq list_ref,vector,chunked_stack,circular_array,stack_array -n 20000000 -length 10000000 -runs 5

pplot -series prog -x seq -y exectime -legend-pos topleft --xtitles-vertical  && evince plots.pdf &

#============================================
# ADDITIONAL PERSISTENT LIFO BENCHMARK

# smaller sizes, all structures:
make opt && prun output.opt -test real_lifo -seq list_ref,pchunked_seq,pchunked_stack_copy_on_write_ref_16,pchunked_stack_ref -n 2000000 -length 10,100,1000,10000,100000,1000000

pplot -mode scatter -series seq --xlog -x length -y exectime --yzero -legend-pos topleft && evince plots.pdf &

cp plots.pdf plots/plots_plifo.pdf && cp results.txt plots/results_plifo.txt


#============================================
# UNIT TESTING OF STRUCTURES

make dbg && prun output.dbg  -test fifo_debug_1 -n 1000 -seq circular_array_big,stdlib_queue

make dbg && prun output.dbg -test lifo_debug_1 -n 1000 -seq stack_array,vector,circular_array_big,list_ref,chunked_stack

  # fixed capacity test
make dbg && prun output.dbg -test lifo_debug_1 -n 100 -chunk 100 -seq pchunk_stack_ref

make dbg && prun output.dbg -test lifo_debug_1 -n 1000 -seq list_ref,pchunk_array_ref,pchunk_stack_ref,pchunked_seq_ref,pchunked_stack_copy_on_write_ref,pchunked_stack_ref,stack_packed_ref

# e.g.
   output.dbg -test lifo_debug_1 -seq pchunked_seq -debug 1


make dbg && prun output.dbg  -test real_random_access -n 2000 -length 500 -seq vector,chunked_stack_256



#============================================
# EPHEMERAL FIFO BENCHMARK

# Push 10k items, then repeat n times: push_back (n/r) items
#  followed by pop_front (n/r) items.

make opt && prun output.opt -test real_fifo -seq circular_array_big,stdlib_queue -n 20000000 -length 10,100,1000,10000,100000,1000000,10000000 -static_array_size 20000000

pplot -mode scatter -series seq --xlog -x length -y exectime --yzero -legend-pos topleft && evince plots.pdf &



#============================================

make dbg && output.dbg -test lifo_debug_1 -chunk 10 -n 50 -seq stack_packed -debug 1
