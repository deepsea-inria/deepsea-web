/home/charguer/.opam/4.04.0+flambda/bin/ocamlopt -O2 str.cmxa unix.cmxa Shared.ml StackPacked.ml -o output.out





exit

make packed.opt  && packed.opt -seq packed -nb_buckets 1 -nb_items 20000 -distrib_mode round_robin

make packed.opt && prun packed.opt -seq list,packed -nb_buckets 1,4,10,100,1000,10000,100000,1000000,10000000,100000000 -nb_items 10000000 -distrib_mode round_robin -nb_runs 3
pplot -mode scatter -series seq --xlog -x nb_buckets -y exectime --yzero -legend-pos topleft && evince plots.pdf &




make packed.opt && prun packed.opt -seq list,packed -nb_buckets 1,2,4,8,10,12 -nb_items 3000000 -distrib_mode round_robin

make packed.opt && \
prun packed.opt -seq list,old_packed,wrap_chunked_stack,packed,chunked_stack,stack_array -nb_buckets 1,4,8,12 -nb_items 3000000 -distrib_mode round_robin && \
pplot -mode scatter -series seq --xlog -x nb_buckets -y exectime --yzero -legend-pos topleft && evince plots.pdf &


make packed.opt && \
prun packed.opt -seq list,wrap_chunked_stack,packed,chunked_stack -nb_buckets 1,4,8,12 -nb_items 3000000 -distrib_mode round_robin && \
pplot -mode scatter -series seq --xlog -x nb_buckets -y exectime --yzero -legend-pos topleft && evince plots.pdf &

