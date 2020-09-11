INCL=$(wildcard include/*)
SRC=$(wildcard design/*)

build/system: tb/main.cpp $(SRC) $(INCL)
	mkdir -p build
	verilator -Wall -Iinclude --top-module system --Mdir build/ -cc $(SRC) --exe --build $<
