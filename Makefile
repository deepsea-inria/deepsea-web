PROJECT_NAME=deepsea

### web page

PROJECT_STYLE_SHEET=deepsea.css
PROJECT_STYLE_SHEET_OPT=-c $(PROJECT_STYLE_SHEET)
PROJECT_SSH_TARGET=yquem.inria.fr:/net/yquem/infosystems/www/gallium/deepsea
REMOTE_DEST=$(PROJECT_SSH_TARGET)
GENERATED_FILES=$(PROJECT_NAME).html $(PROJECT_NAME).pdf
PROJECT_FILES=$(PROJECT_NAME).bib 
PROJECT_BIBS=--biblio $(PROJECT_NAME).bib

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
