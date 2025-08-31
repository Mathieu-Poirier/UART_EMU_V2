##### package metadata #####
PKG          ?= app
VERSION      ?= $(shell [ -f VERSION ] && cat VERSION || echo 0.1.0)

##### tools #####
ZIGCXX       ?= zig c++
ZIGCC        ?= zig cc
INSTALL      ?= install
INSTALL_PROGRAM ?= $(INSTALL)
STRIP        ?= strip

# Windows cross-compilation tools
ZIGCXX_WINDOWS ?= zig c++ -target x86_64-windows-gnu
ZIGCC_WINDOWS  ?= zig cc -target x86_64-windows-gnu

##### install dirs (GNU) #####
prefix       ?= /usr/local
exec_prefix  ?= $(prefix)
bindir       ?= $(exec_prefix)/bin

##### layout #####
SRC_DIR      := src
TEST_DIR     := tests
BUILD_DIR    := build
BIN_DIR      := bin
IMGUI_DIR    := imgui

APP          := $(BIN_DIR)/$(PKG)
DEMO         := $(BIN_DIR)/demo
TESTBINS     := $(patsubst $(TEST_DIR)/%.cpp,$(BIN_DIR)/test_%,$(wildcard $(TEST_DIR)/*.cpp))

SRC_CPP      := $(wildcard $(SRC_DIR)/*.cpp)
TEST_CPP     := $(wildcard $(TEST_DIR)/*.cpp)
DEMO_CPP     := $(wildcard demo/*.cpp)
CRT0         := $(SRC_DIR)/crt0.S

OBJ_APP      := $(patsubst $(SRC_DIR)/%.cpp,$(BUILD_DIR)/freestanding/%.o,$(SRC_CPP)) \
                $(BUILD_DIR)/freestanding/crt0.o

OBJ_SRC_HOSTED := $(patsubst $(SRC_DIR)/%.cpp,$(BUILD_DIR)/hosted/%.o,$(filter-out $(SRC_DIR)/main.cpp,$(SRC_CPP)))

# Dear ImGui sources
IMGUI_SRC    := $(IMGUI_DIR)/imgui.cpp \
                $(IMGUI_DIR)/imgui_draw.cpp \
                $(IMGUI_DIR)/imgui_tables.cpp \
                $(IMGUI_DIR)/imgui_widgets.cpp \
                $(IMGUI_DIR)/backends/imgui_impl_glfw.cpp \
                $(IMGUI_DIR)/backends/imgui_impl_opengl3.cpp

OBJ_IMGUI    := $(patsubst $(IMGUI_DIR)/%.cpp,$(BUILD_DIR)/hosted/imgui/%.o,$(IMGUI_SRC))

OBJ_DEMO     := $(patsubst demo/%.cpp,$(BUILD_DIR)/hosted/demo/%.o,$(DEMO_CPP)) \
                $(OBJ_SRC_HOSTED) $(OBJ_IMGUI)

##### flags #####
CXXFLAGS_COMMON := -std=c++20 -Wall -Wextra -O3 -g -ffunction-sections -fdata-sections
CXXFLAGS_FREESTANDING := -ffreestanding -fno-exceptions -fno-rtti -fno-builtin -fno-stack-protector \
                         -fno-asynchronous-unwind-tables -fno-plt -Wno-main
ASFLAGS_FREESTANDING  := -ffreestanding -nostdlib
LDFLAGS_FREESTANDING  := -nostdlib -static -Wl,--gc-sections -Wl,--build-id=none
LDLIBS_FREESTANDING   :=

CXXFLAGS_HOSTED := -g -I$(IMGUI_DIR) -I$(IMGUI_DIR)/backends
LDFLAGS_HOSTED  :=
LDLIBS_HOSTED   := -lglfw -lGL -ldl -lpthread

# Windows-specific flags
CXXFLAGS_HOSTED_WINDOWS := -g -I$(IMGUI_DIR) -I$(IMGUI_DIR)/backends
LDFLAGS_HOSTED_WINDOWS  :=
LDLIBS_HOSTED_WINDOWS   := -lglfw -lopengl32 -lgdi32 -luser32 -lkernel32 -lwinmm

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

##### build rules (hosted demo - Windows) #####
$(BIN_DIR)/uart-demo.exe: $(OBJ_DEMO) | $(BIN_DIR)
	$(ZIGCXX_WINDOWS) $(LDFLAGS_HOSTED_WINDOWS) -o $@ $(OBJ_DEMO) $(LDLIBS_HOSTED_WINDOWS)

##### build rules (hosted tests) #####
$(BIN_DIR)/test_%: $(BUILD_DIR)/hosted/tests/%.o $(OBJ_SRC_HOSTED) | $(BIN_DIR)
	$(ZIGCXX) $(LDFLAGS_HOSTED) -o $@ $< $(OBJ_SRC_HOSTED) $(LDLIBS_HOSTED)

$(BUILD_DIR)/hosted/%.o: $(SRC_DIR)/%.cpp | $(BUILD_DIR)/hosted
	$(ZIGCXX) $(CXXFLAGS_COMMON) $(CXXFLAGS_HOSTED) -c $< -o $@

$(BUILD_DIR)/hosted/tests/%.o: $(TEST_DIR)/%.cpp | $(BUILD_DIR)/hosted/tests
	$(ZIGCXX) $(CXXFLAGS_COMMON) $(CXXFLAGS_HOSTED) -DTESTING=1 -c $< -o $@

$(BUILD_DIR)/hosted/demo/%.o: demo/%.cpp | $(BUILD_DIR)/hosted/demo
	$(ZIGCXX) $(CXXFLAGS_COMMON) $(CXXFLAGS_HOSTED) -DDEMO=1 -c $< -o $@

$(BUILD_DIR)/hosted/imgui/%.o: $(IMGUI_DIR)/%.cpp | $(BUILD_DIR)/hosted/imgui $(BUILD_DIR)/hosted/imgui/backends
	$(ZIGCXX) $(CXXFLAGS_COMMON) $(CXXFLAGS_HOSTED) -c $< -o $@

##### dirs #####
$(BIN_DIR) \
$(BUILD_DIR)/freestanding \
$(BUILD_DIR)/hosted \
$(BUILD_DIR)/hosted/tests \
$(BUILD_DIR)/hosted/demo \
$(BUILD_DIR)/hosted/imgui \
$(BUILD_DIR)/hosted/imgui/backends:
	mkdir -p $@

##### standard targets #####

# install: do not strip; create dirs; avoid modifying build tree
.PHONY: install
install: all installdirs
	$(INSTALL_PROGRAM) -m 755 $(APP) "$(DESTDIR)$(bindir)/$(PKG)"

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
	mkdir -p "$(DESTDIR)$(bindir)"

# demo: build hosted demo
.PHONY: demo
demo: $(DEMO)
	@echo "== demo built successfully =="

# demo-windows: build hosted demo for Windows
.PHONY: demo-windows
demo-windows: $(BIN_DIR)/uart-demo.exe
	@echo "== Windows demo built successfully =="

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

# clean
.PHONY: clean
clean:
	-rm -rf $(BUILD_DIR) $(BIN_DIR) .cache
