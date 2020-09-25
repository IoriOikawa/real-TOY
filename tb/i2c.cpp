#include <iostream>
#include <iomanip>
#include <string>
#include "Vi2c.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

class tester : public Vi2c {
    VerilatedVcdC _tfp;
    size_t _t;
    bool _dump;
public:
    tester() {
        clk_i = 1;
        eval();
    }

    explicit tester(const std::string &fn) : _t{ 0 }, _dump{ true } {
        trace(&_tfp, 114514);
        _tfp.open(fn.c_str());
        clk_i = 1;
        eval();
        _tfp.dump(_t++);
    }

    ~tester() {
        final();
        if (_dump) _tfp.close();
    }

    void tick() {
        clk_i = 0;
        eval();
        if (_dump) _tfp.dump(_t++);
        clk_i = 1;
        eval();
        if (_dump) _tfp.dump(_t++);
    }
};


int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);
    tester tb{"build/dump.vcd"};
    tb.rst_ni = 0;
    tb.tick();
    tb.rst_ni = 1;
    tb.srst_i = 1;
    tb.tick();
    tb.tick();
    tb.srst_i = 0;
    tb.tick();
    tb.in_daddr_i = 0x22;
    tb.in_addr_i = 0x5a;
    tb.in_data_i = 0xa5;
    tb.in_wen_i = 0;
    tb.scl_i = 1;
    tb.sda_i = 1;
    tb.in_val_i = 1;
    tb.tick();
    tb.in_val_i = 0;
    tb.out_rdy_i = 1;
    tb.tick();
    tb.tick();
    tb.tick();
    tb.tick();
    tb.tick();
    tb.scl_i = 0;
    tb.sda_i = 0;
    for (size_t i{ 0 }; i < 30 * 128; i++)
        tb.tick();
}
