# F-Synth Makefile
# Fortran 2018 Audio Synthesizer Build Configuration

# Compiler settings
FC := gfortran
FFLAGS := -Wall -Wextra -O2 -ffree-form -fimplicit-none
FFLAGS_DEBUG := -Wall -Wextra -g -O0 -ffree-form -fimplicit-none -fbacktrace -fbounds-check
FFLAGS_RELEASE := -O3 -ffree-form -fimplicit-none -march=native

# Directories
SRC_DIR := src
APP_DIR := app
BUILD_DIR := build
OBJ_DIR := $(BUILD_DIR)/obj
BIN_DIR := $(BUILD_DIR)/bin

# Source files
MOD_SOURCES := $(wildcard $(SRC_DIR)/mod_*.f90)
APP_SOURCES := $(wildcard $(APP_DIR)/*.f90)
ALL_SOURCES := $(MOD_SOURCES) $(APP_SOURCES)

# Object files (modules compiled first)
MOD_OBJECTS := $(patsubst $(SRC_DIR)/%.f90,$(OBJ_DIR)/%.o,$(MOD_SOURCES))
APP_OBJECTS := $(patsubst $(APP_DIR)/%.f90,$(OBJ_DIR)/%.o,$(APP_SOURCES))

# Output executable
EXECUTABLE := $(BIN_DIR)/fsynth

# Phony targets
.PHONY: all debug release clean help setup

# Default target
all: $(EXECUTABLE)

# Debug build (with debugging symbols and bounds checking)
debug: FFLAGS := $(FFLAGS_DEBUG)
debug: $(EXECUTABLE)

# Release build (optimized)
release: FFLAGS := $(FFLAGS_RELEASE)
release: $(EXECUTABLE)

# Setup build directories
setup:
	@mkdir -p $(OBJ_DIR)
	@mkdir -p $(BIN_DIR)
	@echo "Build directories created."

# Main executable target
$(EXECUTABLE): $(MOD_OBJECTS) $(APP_OBJECTS) | setup
	$(FC) $(FFLAGS) -o $@ $(MOD_OBJECTS) $(APP_OBJECTS)
	@echo "✓ Build complete: $@"

# Compile module objects
$(OBJ_DIR)/%.o: $(SRC_DIR)/%.f90 | setup
	$(FC) $(FFLAGS) -c -J$(OBJ_DIR) -o $@ $<
	@echo "✓ Compiled: $<"

# Compile application objects
$(OBJ_DIR)/%.o: $(APP_DIR)/%.f90 | setup
	$(FC) $(FFLAGS) -J$(OBJ_DIR) -c -o $@ $<
	@echo "✓ Compiled: $<"

# Fortran module dependencies. A source file that says "use mod_types" needs
# mod_types.mod to exist before it can be compiled.
$(OBJ_DIR)/mod_adsr.o: $(OBJ_DIR)/mod_types.o
$(OBJ_DIR)/mod_oscillations.o: $(OBJ_DIR)/mod_types.o
$(OBJ_DIR)/mod_wav.o: $(OBJ_DIR)/mod_types.o
$(APP_OBJECTS): $(MOD_OBJECTS)

# Clean build artifacts
clean:
	@rm -rf $(BUILD_DIR)
	@echo "✓ Clean complete."

# Help target
help:
	@echo "F-Synth Makefile Targets:"
	@echo "  make              - Build optimized executable"
	@echo "  make debug        - Build with debugging symbols and checks"
	@echo "  make release      - Build with full optimizations"
	@echo "  make clean        - Remove build artifacts"
	@echo "  make help         - Show this help message"
	@echo ""
	@echo "Example usage:"
	@echo "  make              - Standard build"
	@echo "  make debug        - Build for debugging"
	@echo "  make clean && make - Clean rebuild"
