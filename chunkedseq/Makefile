PROJECT_NAME=chunkedseq

#### chunkedseq package

PACKAGES=packages/
CHUNKEDSEQ=$(PACKAGES)/chunkedseq/
CHUNKEDSEQ_CODE=$(CHUNKEDSEQ)/chunkedseq/
CHUNKEDSEQ_CODE_DOC=$(CHUNKEDSEQ_CODE)/doc/

### experiments package

EXPERIMENTS=experiments/
CHUNKEDSEQ_BENCH=$(EXPERIMENTS)/chunkedseq_bench/
PBENCH=$(CHUNKEDSEQ_BENCH)/pbench/

experiments_doc: $(EXPERIMENTS)/chunkedseq_bench.tar.gz
	(cd $(EXPERIMENTS) && tar -xvzf chunkedseq_bench.tar.gz)
	make -C $(PBENCH) chunkedseq.pdf chunkedseq.html
	mv $(PBENCH)/chunkedseq.pdf experiments
	mv $(PBENCH)/chunkedseq.html experiments
	cp $(PBENCH)/chunkedseq.md experiments
	rm -rf $(CHUNKEDSEQ_BENCH)

clean_experiments_doc:
	rm -f experiments/chunkedseq.pdf experiments/chunkedseq.html experiments/chunkedseq.md

### web page

PROJECT_STYLE_SHEET=chunkedseq.css
PROJECT_STYLE_SHEET_OPT=-c $(PROJECT_STYLE_SHEET)
PROJECT_SSH_TARGET=yquem.inria.fr:/net/yquem/infosystems/www/gallium/deepsea
REMOTE_DEST=$(PROJECT_SSH_TARGET)/$(PROJECT_NAME)/
GENERATED_FILES=$(PROJECT_NAME).html $(PROJECT_NAME).pdf
PROJECT_FILES=$(PROJECT_NAME).bib esa-2014-long.pdf 
PROJECT_BIBS=--bibliography $(PROJECT_NAME).bib

%.pdf : %.md
	pandoc $< -s -S $(PROJECT_BIBS) -o $@
%.html : %.md
	pandoc $< -s -S $(PROJECT_BIBS) $(PROJECT_STYLE_SHEET_OPT) -o $@

clean: clean_experiments_doc
	rm -f $(GENERATED_FILES)

### push to server (important: must first run `make clean`)

publish: chunkedseq.html chunkedseq.pdf experiments_doc 
	scp $(PROJECT_STYLE_SHEET) $(REMOTE_DEST)
	scp $(PROJECT_FILES) $(REMOTE_DEST)
	scp -r doc $(REMOTE_DEST)
	scp -r packages $(REMOTE_DEST)
	scp -r experiments $(REMOTE_DEST)
	scp $(PROJECT_NAME).html $(REMOTE_DEST)/index.html
