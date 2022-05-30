AUTOMAKE_OPTIONS = foreign

ACLOCAL_AMFLAGS = -I m4

composed_bin_scripts = \
	asciidoc2txt.sh

generated_files = \
	test-resume.txt \
	test-resume-ext.txt \
	test-resume.html  \
	test-resume.pdf

bin_SCRIPTS = $(composed_bin_scripts)

nobase_bin_SCRIPTS = 

data_DATA = $(generated_files)

edit = sed \
	-e 's|@PACKAGE\@|$(PACKAGE)|g' \
	-e 's|@PACKAGE_BUGREPORT\@|$(PACKAGE_BUGREPORT)|g' \
	-e 's|@PACKAGE_NAME\@|$(PACKAGE_NAME)|g' \
	-e 's|@PACKAGE_URL\@|$(PACKAGE_URL)|g' \
	-e 's|@PACKAGE_VERSION\@|$(PACKAGE_VERSION)|g' \
	-e 's|@datadir\@|$(pkgdatadir)|g' \
	-e 's|@libexecdir\@|$(libexecdir)|g' \
	-e 's|@prefix\@|$(prefix)|g'

$(composed_bin_scripts): % : Makefile $(srcdir)/%.in
	rm -f $@ $@.tmp
	mkdir -p $$(dirname $@)
	$(edit) $(srcdir)/$@.in > $@.tmp
	chmod +x $@.tmp
	mv $@.tmp $@

test-resume.txt: % : Makefile asciidoc2txt.sh test-resume.adoc
	echo "Generating '$@'"
	pwd
	./asciidoc2txt.sh test-resume.adoc

test-resume-ext.txt: % : Makefile asciidoc2txt.sh test-resume.adoc
	echo "Generating '$@'"
	./asciidoc2txt.sh -e test-resume.adoc

test-resume.html: % : Makefile asciidoc2txt.sh test-resume.adoc
	echo "Generating '$@'"
	asciidoctor -v test-resume.adoc

test-resume.pdf: % : Makefile asciidoc2txt.sh test-resume.adoc
	echo "Generating '$@'"
	asciidoctor-pdf -v test-resume.adoc

test_files = tests/*

EXTRA_DIST = bootstrap configure.ac COPYING m4 mit-plus-license.txt README.md \
	version.sh $(addsuffix .in, $(composed_bin_scripts)) \
	$(nobase_bin_SCRIPTS) test-resume.adoc $(generated_files) $(test_files)

CLEANFILES = $(bin_SCRIPTS)

MAINTAINERCLEANFILES = aclocal.m4 compile config.h* configure depcomp \
 install-sh Makefile.in missing $(PACKAGE)-*.gz

maintainer-clean-local:
	rm -rf m4 .deps

.PHONY: help

help:
	@echo "Targets:"
	@echo "  make install"
	@echo "  make dist"
	@echo "  make distcheck"
	@echo "  make distclean"
	@echo "  make maintainer-clean"
