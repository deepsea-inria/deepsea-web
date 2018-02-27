all: pldi18.html pldi18.pdf

PROJECT_NAME=heartbeat
PROJECT_BIBS=--bibliography pldi18.bib --filter pandoc-citeproc --metadata link-citations=true --csl chicago-author-date.csl
PROJECT_STYLE_SHEET=pldi18.css
PROJECT_SSH_TARGET=yquem.inria.fr:/net/yquem/infosystems/www/gallium/deepsea
REMOTE_DEST=$(PROJECT_SSH_TARGET)/$(PROJECT_NAME)

%.pdf : %.md
	pandoc $< -s $(PROJECT_BIBS) -o $@

%.html : %.md
	pandoc $< -s -c $(PROJECT_STYLE_SHEET) $(PROJECT_BIBS) -o $@

publish: $(PROJECT_FILES)
	scp $(PROJECT_STYLE_SHEET) $(REMOTE_DEST)
	scp pldi18.html $(REMOTE_DEST)/index.html

clean:
	rm -f *.html *.pdf
