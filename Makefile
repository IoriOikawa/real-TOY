INCL=$(wildcard include/*)
SRC=$(wildcard design/*)

build/Vsystem: tb/main.cpp $(SRC) $(INCL)
	mkdir -p build
	verilator --trace -Wall -Iinclude --top-module system --Mdir build/ -cc $(SRC) --exe $<
	$(MAKE) -C build --file Vsystem.mk
