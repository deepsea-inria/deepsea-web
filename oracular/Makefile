PROJECT_NAME=oracular

### web page

PROJECT_STYLE_SHEET=$(PROJECT_NAME).css
PROJECT_STYLE_SHEET_OPT=-c $(PROJECT_STYLE_SHEET)
PROJECT_SSH_TARGET=yquem.inria.fr:/net/yquem/infosystems/www/gallium/deepsea
REMOTE_DEST=$(PROJECT_SSH_TARGET)/$(PROJECT_NAME)
GENERATED_FILES=$(PROJECT_NAME).html $(PROJECT_NAME).pdf
PNG_FILES=
TALK_FILES=
PAPER_FILES=2011_10_26_talk_oopsla_oracle.pdf oracle_scheduling.pdf
PROJECT_FILES=$(PROJECT_NAME).bib $(PNG_FILES) $(PAPER_FILES)
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
