PATH=~/pbench:$PATH
ln -s ~/bench/timeout.out timeout.out



#============================================
# LIFO BENCHMARK

# Push 10k items, then repeat n times: push_back (n/r) items
#  followed by pop_back (n/r) items.

make dbg && prun output.dbg -test lifo_debut_1 -seq sized_array,vector,circular_array,ocaml_list,chunked_stack

make opt && prun output.opt  -test lifo_1 -seq sized_array,vector,circular_array,ocaml_list,chunked_stack -n 100 -r 10


#============================================
# FIFO BENCHMARK

# Push 10k items, then repeat n times: push_back (n/r) items
#  followed by pop_front (n/r) items.

make dbg && prun output.dbg  -test fifo_debug_1

make opt && prun output.opt  -test fifo_1 -seq circular_array,ocaml_queue -n 100 -r 10


#============================================

# -chunk 3


