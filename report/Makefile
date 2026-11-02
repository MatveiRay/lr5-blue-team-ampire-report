.DEFAULT_GOAL := all
.DELETE_ON_ERROR:

SOURCES = $(filter-out README.md,$(wildcard *.md))
FILES = $(patsubst %.md,_output/%.docx,$(SOURCES))
FILES += $(patsubst %.md,_output/%.pdf,$(SOURCES))

PANDOC ?= pandoc
CROSSREF ?= pandoc-crossref
PYTHON ?= python3
RESOURCE_PATH = .:image:pandoc
ifeq ($(OS),Windows_NT)
RESOURCE_PATH = .;image;pandoc
endif
FILTERS = --lua-filter=pandoc/layout.lua --filter "$(CROSSREF)" --lua-filter=pandoc/tables.lua
OPTIONS = --standalone --number-sections --resource-path="$(RESOURCE_PATH)"
OPTIONS += --metadata-file=pandoc/metadata.yaml
PDF_ENGINE = --pdf-engine=xelatex --pdf-engine-opt=--shell-escape
PDF_OPTIONS =
FORMAT_OPTIONS = --top-level-division=section
BIB_OPTIONS = --citeproc
DOCX_OPTIONS = --reference-doc=pandoc/reference.docx
SUPPORT = $(wildcard pandoc/*.lua pandoc/*.tex pandoc/*.yaml pandoc/*.docx pandoc/*.py pandoc/*.ps1 pandoc/*.txt) $(wildcard image/*.png)

.PHONY: all pdf docx check versions clean cleanall

all: $(FILES)
pdf: $(patsubst %.md,_output/%.pdf,$(SOURCES))
docx: $(patsubst %.md,_output/%.docx,$(SOURCES))

_output/%.docx: %.md $(SUPPORT)
	mkdir -p _output
	"$(PANDOC)" "$<" $(FILTERS) $(OPTIONS) $(BIB_OPTIONS) $(DOCX_OPTIONS) -o "$@"
	"$(PYTHON)" pandoc/finalize_docx.py "$@" --source "$<"

_output/%.pdf: %.md $(SUPPORT)
	mkdir -p _output
	"$(PANDOC)" "$<" $(FILTERS) $(PDF_ENGINE) $(PDF_OPTIONS) $(BIB_OPTIONS) $(FORMAT_OPTIONS) $(OPTIONS) -o "$@"

check:
	"$(PANDOC)" --version
	"$(CROSSREF)" --version
	xelatex --version
	"$(PYTHON)" -c "import docx, pdfplumber; print('Python dependencies OK')"

versions:
	"$(PANDOC)" --version | head -1
	"$(CROSSREF)" --version
	xelatex --version | head -1
	"$(PYTHON)" --version

clean:
	rm -f -- $(FILES) *~

cleanall: clean
