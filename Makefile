##### package metadata #####
PKG          ?= app
VERSION      ?= $(shell [ -f VERSION ] && cat VERSION || echo 0.1.0)

##### tools #####
ZIGCXX       ?= zig c++
ZIGCC        ?= zig cc
AR           ?= ar
RANLIB       ?= ranlib
INSTALL      ?= install
INSTALL_PROGRAM ?= $(INSTALL)
INSTALL_DATA ?= $(INSTALL) -m 644
STRIP        ?= strip
CTAGS        ?= ctags
SHELL        ?= /bin/sh

##### install dirs (GNU) #####
prefix       ?= /usr/local
exec_prefix  ?= $(prefix)
bindir       ?= $(exec_prefix)/bin
libdir       ?= $(exec_prefix)/lib
datadir      ?= $(prefix)/share
infodir      ?= $(datadir)/info
mandir       ?= $(datadir)/man
htmldir      ?= $(datadir)/doc/$(PKG)/html
dvidir       ?= $(datadir)/doc/$(PKG)/dvi
pdfdir       ?= $(datadir)/doc/$(PKG)/pdf
psdir        ?= $(datadir)/doc/$(PKG)/ps

##### layout #####
SRC_DIR      := src
TEST_DIR     := tests
BUILD_DIR    := build
BIN_DIR      := bin

APP          := $(BIN_DIR)/$(PKG)
DEMO         := $(BIN_DIR)/demo
TESTBINS     := $(patsubst $(TEST_DIR)/%.cpp,$(BIN_DIR)/test_%,$(wildcard $(TEST_DIR)/*.cpp))

SRC_CPP      := $(wildcard $(SRC_DIR)/*.cpp)
TEST_CPP     := $(wildcard $(TEST_DIR)/*.cpp)
DEMO_CPP     := $(wildcard demo/*.cpp)
CRT0         := $(SRC_DIR)/crt0.S

OBJ_APP      := $(patsubst $(SRC_DIR)/%.cpp,$(BUILD_DIR)/freestanding/%.o,$(SRC_CPP)) \
                $(BUILD_DIR)/freestanding/crt0.o
OBJ_DEMO     := $(patsubst demo/%.cpp,$(BUILD_DIR)/hosted/demo/%.o,$(DEMO_CPP)) \
                $(patsubst $(SRC_DIR)/%.cpp,$(BUILD_DIR)/hosted/%.o,$(filter-out $(SRC_DIR)/main.cpp,$(SRC_CPP)))
OBJ_SRC_HOSTED := $(patsubst $(SRC_DIR)/%.cpp,$(BUILD_DIR)/hosted/%.o,$(filter-out $(SRC_DIR)/main.cpp,$(SRC_CPP)))

##### flags #####
CXXFLAGS_COMMON := -std=c++20 -Wall -Wextra -O3 -g -ffunction-sections -fdata-sections
CXXFLAGS_FREESTANDING := -ffreestanding -fno-exceptions -fno-rtti -fno-builtin -fno-stack-protector \
                         -fno-asynchronous-unwind-tables -fno-plt -Wno-main
ASFLAGS_FREESTANDING  := -ffreestanding -nostdlib
LDFLAGS_FREESTANDING  := -nostdlib -static -Wl,--gc-sections -Wl,--build-id=none
LDLIBS_FREESTANDING   :=

CXXFLAGS_HOSTED := -g
LDFLAGS_HOSTED  :=
LDLIBS_HOSTED   :=

##### default #####
.PHONY: all
all: $(APP)

##### build rules (freestanding) #####
$(APP): $(OBJ_APP) | $(BIN_DIR)
	$(ZIGCXX) $(LDFLAGS_FREESTANDING) -o $@ $(OBJ_APP) $(LDLIBS_FREESTANDING)

$(BUILD_DIR)/freestanding/crt0.o: $(CRT0) | $(BUILD_DIR)/freestanding
	$(ZIGCC) $(ASFLAGS_FREESTANDING) -c $< -o $@

$(BUILD_DIR)/freestanding/%.o: $(SRC_DIR)/%.cpp | $(BUILD_DIR)/freestanding
	$(ZIGCXX) $(CXXFLAGS_COMMON) $(CXXFLAGS_FREESTANDING) -c $< -o $@

##### build rules (hosted demo) #####
$(DEMO): $(OBJ_DEMO) | $(BIN_DIR)
	$(ZIGCXX) $(LDFLAGS_HOSTED) -o $@ $(OBJ_DEMO) $(LDLIBS_HOSTED)

##### build rules (hosted tests) #####
$(BIN_DIR)/test_%: $(BUILD_DIR)/hosted/tests/%.o $(OBJ_SRC_HOSTED) | $(BIN_DIR)
	$(ZIGCXX) $(LDFLAGS_HOSTED) -o $@ $< $(OBJ_SRC_HOSTED) $(LDLIBS_HOSTED)

$(BUILD_DIR)/hosted/%.o: $(SRC_DIR)/%.cpp | $(BUILD_DIR)/hosted
	$(ZIGCXX) $(CXXFLAGS_COMMON) $(CXXFLAGS_HOSTED) -c $< -o $@

$(BUILD_DIR)/hosted/tests/%.o: $(TEST_DIR)/%.cpp | $(BUILD_DIR)/hosted/tests
	$(ZIGCXX) $(CXXFLAGS_COMMON) $(CXXFLAGS_HOSTED) -DTESTING=1 -c $< -o $@

$(BUILD_DIR)/hosted/demo/%.o: demo/%.cpp | $(BUILD_DIR)/hosted/demo
	$(ZIGCXX) $(CXXFLAGS_COMMON) $(CXXFLAGS_HOSTED) -DDEMO=1 -c $< -o $@

##### dirs #####
$(BIN_DIR) \
$(BUILD_DIR)/freestanding \
$(BUILD_DIR)/hosted \
$(BUILD_DIR)/hosted/tests \
$(BUILD_DIR)/hosted/demo:
	mkdir -p $@

##### standard GNU user targets #####

# install: do not strip; create dirs; avoid modifying build tree
.PHONY: install
install: all installdirs
	$(INSTALL_PROGRAM) -m 755 $(APP) "$(DESTDIR)$(bindir)/$(PKG)"
	@# simple smoke check if desired (freestanding binaries may not run on host)
	@true

# install-strip: like install, but strip installed copy
.PHONY: install-strip
install-strip: all installdirs
	$(INSTALL_PROGRAM) -m 755 $(APP) "$(DESTDIR)$(bindir)/$(PKG)"
	$(STRIP) "$(DESTDIR)$(bindir)/$(PKG)"

# uninstall: remove installed files only
.PHONY: uninstall
uninstall:
	-rm -f  "$(DESTDIR)$(bindir)/$(PKG)"

# installdirs: create all install dirs (DESTDIR-aware)
.PHONY: installdirs
installdirs:
	mkdir -p "$(DESTDIR)$(bindir)" \
	         "$(DESTDIR)$(datadir)" \
	         "$(DESTDIR)$(libdir)" \
	         "$(DESTDIR)$(infodir)" \
	         "$(DESTDIR)$(mandir)" \
	         "$(DESTDIR)$(htmldir)" \
	         "$(DESTDIR)$(dvidir)" \
	         "$(DESTDIR)$(pdfdir)" \
	         "$(DESTDIR)$(psdir)"

# demo: build & run hosted demo
.PHONY: demo
demo: $(DEMO)
	@echo "== running UART emulator demo =="
	$(DEMO)

# check: build & run tests (hosted)
.PHONY: check test
check: test
test: $(TESTBINS)
	@echo "== running all tests =="
	@for test in $(TESTBINS); do \
		echo "Running $$test..."; \
		$$test || exit 1; \
	done
	@echo "All tests completed successfully!"

# installcheck: tests that require installed files (optional)
.PHONY: installcheck
installcheck:
	@echo "No installcheck defined." && true

# clean tiers
.PHONY: clean mostlyclean distclean maintainer-clean
clean:
	-rm -rf $(BUILD_DIR) $(BIN_DIR) .cache

mostlyclean:
	@$(MAKE) clean

distclean:
	@$(MAKE) clean
	-rm -f config.log config.status Makefile.config

maintainer-clean:
	@echo 'This command is intended for maintainers to use; it'
	@echo 'deletes files that may need special tools to rebuild.'
	@$(MAKE) distclean
	-rm -f TAGS
	-rm -rf dist

# TAGS (ctags)
.PHONY: TAGS
TAGS:
	$(CTAGS) -R --languages=C,C++ $(SRC_DIR) $(TEST_DIR) 2>/dev/null || true

##### docs (no-ops unless you add Texinfo) #####
MAKEINFO   ?= makeinfo
TEXI2DVI   ?= texi2dvi
TEXI2HTML  ?= makeinfo --no-split --html

DOC_TEXI   ?=

.PHONY: info dvi html pdf ps
info:
	@if [ -n "$(DOC_TEXI)" ]; then \
	  $(MAKEINFO) $(DOC_TEXI); \
	else echo "No Texinfo docs."; fi

dvi:
	@if [ -n "$(DOC_TEXI)" ]; then \
	  $(TEXI2DVI) $(DOC_TEXI); \
	else echo "No Texinfo docs."; fi

html:
	@if [ -n "$(DOC_TEXI)" ]; then \
	  $(TEXI2HTML) $(DOC_TEXI); \
	else echo "No Texinfo docs."; fi

pdf:
	@if [ -n "$(DOC_TEXI)" ]; then \
	  $(MAKEINFO) --pdf $(DOC_TEXI); \
	else echo "No Texinfo docs."; fi

ps:
	@echo "PS doc generation not configured."; true

# install-*doc targets (optional; call explicitly)
.PHONY: install-html install-dvi install-pdf install-ps
install-html: html installdirs
	@if ls *.html >/dev/null 2>&1; then \
	  $(INSTALL_DATA) *.html "$(DESTDIR)$(htmldir)"; \
	else echo "No HTML to install."; fi

install-dvi: dvi installdirs
	@if ls *.dvi >/dev/null 2>&1; then \
	  $(INSTALL_DATA) *.dvi "$(DESTDIR)$(dvidir)"; \
	else echo "No DVI to install."; fi

install-pdf: pdf installdirs
	@if ls *.pdf >/dev/null 2>&1; then \
	  $(INSTALL_DATA) *.pdf "$(DESTDIR)$(pdfdir)"; \
	else echo "No PDF to install."; fi

install-ps: ps installdirs
	@if ls *.ps  >/dev/null 2>&1; then \
	  $(INSTALL_DATA) *.ps  "$(DESTDIR)$(psdir)"; \
	else echo "No PS to install."; fi

##### release tarball #####
DISTDIR := dist/$(PKG)-$(VERSION)

.PHONY: dist
dist: clean
	mkdir -p "$(DISTDIR)"
	cp -a $(SRC_DIR) $(TEST_DIR) Makefile LICENSE README* VERSION 2>/dev/null "$(DISTDIR)" || true
	( cd dist && tar -czf "$(PKG)-$(VERSION).tar.gz" "$(PKG)-$(VERSION)" )
	@echo "Created dist/$(PKG)-$(VERSION).tar.gz"