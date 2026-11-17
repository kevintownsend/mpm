
.PHONY: all poster clean

all: paper.pdf

paper.pdf: paper.tex paper.bib
	pdflatex paper
	bibtex paper
	pdflatex paper
	pdflatex paper
	while grep -q '^LaTeX Warning: Label(s) may have changed' paper.log; do \
		pdflatex paper; \
	done

poster:
	cd poster && pdflatex poster && bibtex poster && pdflatex poster && pdflatex poster

clean:
	$(RM) *.log *.aux *.bbl *.blg *.out *.toc *.lof *.lot *.fls *.fdb_latexmk *.synctex.gz paper.pdf
	$(RM) poster/*.log poster/*.aux poster/*.bbl poster/*.blg poster/*.out poster/*.toc poster/*.run.xml poster/*-blx.bib poster/*.bcf poster/poster.pdf
