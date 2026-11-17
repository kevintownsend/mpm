
.PHONY: all clean

all: paper.pdf

paper.pdf: paper.tex paper.bib
	pdflatex paper
	bibtex paper
	pdflatex paper
	pdflatex paper
	while grep -q '^LaTeX Warning: Label(s) may have changed' paper.log; do \
		pdflatex paper; \
	done

clean:
	$(RM) *.log *.aux *.bbl *.blg *.out *.toc *.lof *.lot *.fls *.fdb_latexmk *.synctex.gz paper.pdf


