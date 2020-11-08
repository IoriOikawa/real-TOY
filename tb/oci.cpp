#include <iostream>
#include <iomanip>
#include <string>
#include "Voci.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

class tester : public Voci {
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
    tb.tick();
    tb.tick();
    tb.gpio_i = 0x5aa5a55a5aa5a55a;
    tb.lcd_bcd_i[0] = 0x1;
    tb.lcd_bcd_i[1] = 0x2;
    tb.lcd_bcd_i[2] = 0x3;
    tb.lcd_bcd_i[3] = 0x4;
    tb.scl_i = 0;
    tb.sda_i = 0;
    for (size_t i{ 0 }; i < 192 * 64 * 64; i++)
        tb.tick();
}
