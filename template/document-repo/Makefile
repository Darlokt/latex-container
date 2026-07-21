MAIN ?= main
BUILD_DIR ?= build

.PHONY: all latex latex-shell markdown mermaid hooks hooks-run clean

all: latex

latex:
	latexmk -pdf -synctex=1 -interaction=nonstopmode -halt-on-error \
		-file-line-error -outdir="$(BUILD_DIR)" "$(MAIN).tex"

latex-shell:
	latexmk -pdf -shell-escape -synctex=1 -interaction=nonstopmode \
		-halt-on-error -file-line-error -outdir="$(BUILD_DIR)" "$(MAIN).tex"

markdown:
	mkdir -p "$(BUILD_DIR)"
	pandoc manuscript.md --citeproc --bibliography=references.bib \
		--pdf-engine=lualatex --output="$(BUILD_DIR)/manuscript.pdf"

mermaid:
	mkdir -p "$(BUILD_DIR)"
	mmdc --input figures/diagram.mmd --output "$(BUILD_DIR)/diagram.svg"

hooks:
	prek install

hooks-run:
	prek run --all-files

clean:
	latexmk -C -outdir="$(BUILD_DIR)" "$(MAIN).tex"
	rm -rf "$(BUILD_DIR)"
