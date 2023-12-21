#!Makefile

# SPDX-License-Identifier: LGPL-3-or-later
# Copyright 2023 Vantosh
#
# Funded by NGI Search Programme HORIZON-CL4-2021-HUMAN-01 2022,
# https://www.ngisearch.eu/, EU Programme 101069364.

default all: pdf

TEXFILE=svp64

TMPDIR:=$(shell mktemp -d /tmp/latex.XXXX)
FIRSTTAG:=$(shell git describe --abbrev=0 --tags --always)
RELTAG:=$(shell git describe --tags --long --always --dirty='-*' --match '[0-9]*.*')

pdf: gitinfo tex

.PHONY: gitinfo
gitinfo:
	@git --no-pager log -1 --date=short --decorate=short --pretty=format:"\usepackage[shash={%h},lhash={%H},authname={%an},authemail={%ae},authsdate={%ad},authidate={%ai},authudate={%at},commname={%an},commemail={%ae},commsdate={%ad},commidate={%ai},commudate={%at},refnames={%d},firsttagdescribe="${FIRSTTAG}",reltag="${RELTAG}"]{gitexinfo}" HEAD > $(TMPDIR)/gitHeadLocal.gin

tex: $(TEXFILE).tex
	@test -d $(TMPDIR) || mkdir $(TMPDIR)
	@echo "Running 2 compiles $(TMPDIR)"
	@pdflatex -output-directory=$(TMPDIR) -interaction=batchmode -file-line-error -no-shell-escape $< > /dev/null
	@makeglossaries -d $(TMPDIR) $(TEXFILE)
	@pdflatex -output-directory=$(TMPDIR) -interaction=batchmode -file-line-error -no-shell-escape $< > /dev/null
	@cp $(TMPDIR)/$(TEXFILE).pdf .
	@echo $(FIRSTTAG) > version
	@echo "$(TEXFILE) PDF Ready"

.PHONY: clean
clean:
	@rm -rf /tmp/latex.*

cleanall:
	@rm -rf /tmp/latex.*
	@rm -f $(TEXFILE).pdf
