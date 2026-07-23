SRC_FILEPATH=src/tcl-calc.tcl
ICO_FILEPATH=assets/tcl-calc.ico
BIN_FILENAME=tcl-calc

# Download @ https://freewrap.dengensys.com/
FREEWRAP_EXE_FILEPATH=~/freewrap/win64/freewrap.exe


all: build-linux


build-linux:
	freewrap $(SRC_FILEPATH) -o $(BIN_FILENAME)


build-windows:
	freewrap $(SRC_FILEPATH) -w $(FREEWRAP_EXE_FILEPATH) -i $(ICO_FILEPATH) -o $(BIN_FILENAME).exe
