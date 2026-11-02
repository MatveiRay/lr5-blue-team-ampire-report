.DEFAULT_GOAL := all
ifneq ($(wildcard .venv/bin/python),)
PYTHON ?= $(abspath .venv/bin/python)
export PYTHON
endif
.PHONY: all pdf docx check versions clean cleanall
all pdf docx check versions clean cleanall:
	$(MAKE) -C report $@
