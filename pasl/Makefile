PROJECT_NAME=pasl
PROJECT_STYLE_SHEET=-c ../deepsea.css
PROJECT_SSH_TARGET=yquem.inria.fr:/net/yquem/infosystems/www/gallium/deepsea
GENERATED_FILES=$(PROJECT_NAME).html $(PROJECT_NAME).pdf
PROJECT_FILES=$(GENERATED_FILES) $(PROJECT_NAME).bib $(PROJECT_NAME).tar.gz
PROJECT_BIBS=--biblio $(PROJECT_NAME).bib

pdf:
	pandoc $(PROJECT_NAME).md -s -S $(PROJECT_BIBS) -o $(PROJECT_NAME).pdf

html:
	pandoc $(PROJECT_NAME).md -s -S $(PROJECT_BIBS) $(PROJECT_STYLE_SHEET) -o $(PROJECT_NAME).html

publish:
	scp $(PROJECT_FILES) $(PROJECT_SSH_TARGET)/$(PROJECT_NAME)/index.html

clean:
	rm -f $(GENERATED_FILES)
