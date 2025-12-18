
PACKAGE=acmart

DEV=-dev # To switch dev on
#DEV=


BIBLATEXFILES= $(wildcard *.bbx) $(wildcard *.cbx) $(wildcard *.dbx) $(wildcard *.lbx)

SAMPLEBIBLATEXFILES=$(patsubst %,samples/%,$(BIBLATEXFILES))


all: paper.pdf

paper.pdf:  paper.dtx   $(PACKAGE).cls
	pdflatex paper
	- bibtex paper
	pdflatex paper
	- makeindex -s gind.ist -o paper.ind paper.idx
	- makeindex -s gglo.ist -o paper.gls paper.glo
	pdflatex paper
	while ( grep -q '^LaTeX Warning: Label(s) may have changed' paper.log) \
	do pdflatex paper; done

clean:
	$(RM)  *.log *.aux \
	*.cfg *.glo *.idx *.toc \
	*.ilg *.ind *.out *.lof \
	*.lot *.bbl *.blg *.gls *.cut *.hd \
	*.dvi *.ps *.thm *.tgz *.zip *.rpi paper.pdf


