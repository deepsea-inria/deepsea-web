PROJECT_NAME=pasl

### web page

PROJECT_STYLE_SHEET=$(PROJECT_NAME).css
PROJECT_STYLE_SHEET_OPT=-c $(PROJECT_STYLE_SHEET)
PROJECT_SSH_TARGET=yquem.inria.fr:/net/yquem/infosystems/www/gallium/deepsea
REMOTE_DEST=$(PROJECT_SSH_TARGET)/$(PROJECT_NAME)
GENERATED_FILES=$(PROJECT_NAME).html $(PROJECT_NAME).pdf
PNG_FILES=evaluation.png lemma.png \
          speedup_matmul_3500.png speedup_string_10000000000.png \
          waiting_matmul_3500.png view_color_lg.png
TALK_FILES=2011_10_26_talk_oopsla_oracle.pdf 2012_01_28_talk_damp_par.pdf \
           2014_09_08_talk_esa_chunked.pdf ppopp2013-slides.pdf
PAPER_FILES=damp2012_primitives.pdf oracle_scheduling.pdf ppopp13.pdf chunkedseq.pdf
PROJECT_FILES=$(PROJECT_NAME).bib $(PNG_FILES) $(PAPER_FILES) $(TALK_FILES)
PROJECT_BIBS=--bibliography $(PROJECT_NAME).bib

%.pdf : %.md
	pandoc $< -s -S $(PROJECT_BIBS) -o $@
%.html : %.md
	pandoc $< -s -S $(PROJECT_BIBS) $(PROJECT_STYLE_SHEET_OPT) -o $@

clean: 
	rm -f $(GENERATED_FILES)

### push to server (important: must first run `make clean`)

publish: $(PROJECT_FILES)
	scp $(PROJECT_STYLE_SHEET) $(REMOTE_DEST)
	scp $(PROJECT_FILES) $(REMOTE_DEST)
	scp $(PROJECT_NAME).html $(REMOTE_DEST)/index.html
