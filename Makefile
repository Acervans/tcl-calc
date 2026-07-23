SRC_FILEPATH=src/tcl-calc.tcl
ICO_FILEPATH=assets/tcl-calc.ico

BIN_FILENAME=tcl-calc
LINUX_SUFFIX=linux-x86_64
WIN_SUFFIX=win64.exe

# Download @ https://freewrap.dengensys.com/
FREEWRAP_EXE_FILEPATH=~/freewrap/win64/freewrap.exe


all: build-linux


build-linux:
	freewrap $(SRC_FILEPATH) -o $(BIN_FILENAME)-$(LINUX_SUFFIX)


build-windows:
	freewrap $(SRC_FILEPATH) -w $(FREEWRAP_EXE_FILEPATH) -i $(ICO_FILEPATH) -o $(BIN_FILENAME)-$(WIN_SUFFIX)
