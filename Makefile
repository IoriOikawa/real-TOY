INCL=$(wildcard include/*)
SRC=$(wildcard design/*)

VLT=verilator -Wall -Iinclude --top-module system

all: verif test fpga

verif: build/repl build/batch build/sim

build/repl: tb/repl.cpp $(SRC) $(INCL)
	mkdir -p build/repl.build/
	$(VLT) --Mdir build/repl.build/ --exe --trace -cc $(SRC) $<
	$(MAKE) -C build/repl.build/ --file Vsystem.mk
	cp repl.build/Vsystem $@

build/batch: tb/batch.cpp $(SRC) $(INCL)
	mkdir -p build/batch.build/
	$(VLT) --Mdir build/batch.build/ --exe -cc $(SRC) $<
	$(MAKE) -C build/batch.build/ --file Vsystem.mk
	cp batch.build/Vsystem $@

build/sim.build/%.class: sim/%.java
	javac -d build/sim.build/ $<

build/sim: scripts/sim.sh build/sim.build/TOY.class build/sim.build/In.class
	cp $< $@

.PHONY: all verif test fpga
