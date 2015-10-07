PROJECT_NAME=pbench

### web page

PROJECT_STYLE_SHEET=$(PROJECT_NAME).css
PROJECT_STYLE_SHEET_OPT=-c $(PROJECT_STYLE_SHEET)
PROJECT_SSH_TARGET=yquem.inria.fr:/net/yquem/infosystems/www/gallium/deepsea
REMOTE_DEST=$(PROJECT_SSH_TARGET)/$(PROJECT_NAME)
DOCUMENTATION_FILES=pplot.pdf pplot.html prun.pdf prun.html pplot.md prun.md
GENERATED_FILES=$(PROJECT_NAME).html $(PROJECT_NAME).pdf
PNG_FILES=barplots.png speedup.png tables.png
TALK_FILES=
PAPER_FILES=work-inflation.pdf
PROJECT_FILES=$(PROJECT_NAME).bib $(PNG_FILES) $(PAPER_FILES)
PROJECT_BIBS=--bibliography $(PROJECT_NAME).bib

%.pdf : %.md
	pandoc $< -s -S $(PROJECT_BIBS) -o $@
%.html : %.md
	pandoc $< -s -S $(PROJECT_BIBS) $(PROJECT_STYLE_SHEET_OPT) -o $@

clean: 
	rm -f $(GENERATED_FILES)

git:
	git clone https://github.com/deepsea-inria/pbench.git tmp
	cp tmp/pplot.md tmp/prun.md .
	rm -rf tmp

doc2: git pplot.pdf pplot.html prun.html

### push to server (important: must first run `make clean`)

publish: doc2 $(PROJECT_FILES)
	scp $(PROJECT_STYLE_SHEET) $(REMOTE_DEST)
	scp $(PROJECT_FILES) $(REMOTE_DEST)
	scp $(PROJECT_NAME).html $(REMOTE_DEST)/index.html
	scp $(DOCUMENTATION_FILES) $(REMOTE_DEST)
