PROJECT_NAME=pctl

# to generate documentation:
#   make PCTL=<path to pctl> doc

### experiments package

EXPERIMENTS=experiments/
PCTL_BENCH=$(EXPERIMENTS)/pctl_bench/
PBENCH=$(PCTL_BENCH)/pbench/

### web page

PROJECT_STYLE_SHEET=pctl.css
PROJECT_STYLE_SHEET_OPT=-c $(PROJECT_STYLE_SHEET)
PROJECT_SSH_TARGET=yquem.inria.fr:/net/yquem/infosystems/www/gallium/deepsea
REMOTE_DEST=$(PROJECT_SSH_TARGET)/$(PROJECT_NAME)/
GENERATED_FILES=$(PROJECT_NAME).html $(PROJECT_NAME).pdf
PROJECT_FILES=$(PROJECT_NAME).bib 
PROJECT_BIBS=--bibliography $(PROJECT_NAME).bib

%.pdf : %.md
	pandoc $< -s -S $(PROJECT_BIBS) -o $@
%.html : %.md
	pandoc $< -s -S $(PROJECT_BIBS) $(PROJECT_STYLE_SHEET_OPT) -o $@

PCTL_DOC=$(PCTL)/doc

doc2: $(PCTL_DOC)/pctl.md
	make -C $(PCTL_DOC) pctl.html5 pctl.pdf
	cp $(PCTL_DOC)/pctl.css $(PCTL_DOC)/pctl.html5  $(PCTL_DOC)/pctl.pdf doc
	mv doc/pctl.html5 doc/pctl.html

clean: 
	rm -f $(GENERATED_FILES)

### push to server (important: must first run `make clean`)

publish: pctl.html pctl.pdf doc2
	scp $(PROJECT_STYLE_SHEET) $(REMOTE_DEST)
	scp $(PROJECT_FILES) $(REMOTE_DEST)
	scp -r doc $(REMOTE_DEST)
	scp $(PROJECT_NAME).html $(REMOTE_DEST)/index.html
