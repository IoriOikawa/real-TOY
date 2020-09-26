VIVADO?=/opt/Xilinx/Vivado/2020.1
INCL=$(wildcard include/*)
SRC=$(wildcard design/*)
CONSTR=$(wildcard constr/*)
XCI=$(patsubst ip/%.xci,%,$(wildcard ip/*.xci))

PART=xc7s25csga225-1
export VIVADO
export PART

VLT=verilator -Wall -Iinclude --top-module system

all: verif test build

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

build: build/output.bit

program: script/program.tcl script/common.tcl build/output.bit
	./script/launch.sh $<

build/post_synth.dcp: script/synth.tcl script/common.tcl $(DESIGN) constr/timing.xdc
	./script/launch.sh $< $(XCI)

define IP_TEMPLATE

build/ip/$1/$1.dcp: script/synth_ip.tcl ip/$1.xci script/common.tcl
	./script/launch.sh $$^

build/post_synth.dcp: build/ip/$1/$1.dcp

endef

$(foreach x,$(XCI),$(eval $(call IP_TEMPLATE,$(x))))

build/post_opt.dcp: script/opt.tcl script/common.tcl build/post_synth.dcp constr/debug.xdc
	./script/launch.sh $<

build/post_place.dcp: script/place.tcl script/common.tcl build/post_opt.dcp constr/pltw-s7.xdc
	./script/launch.sh $<

build/output.bit: script/route.tcl script/common.tcl build/post_place.dcp
	./script/launch.sh $<

constr/debug.xdc:
	touch $@

clean:
	rm -rf build/

.PHONY: all verif test build program clean
