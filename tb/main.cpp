#include <iostream>
#include <iomanip>
#include <string>
#include "Vsystem.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

class tester : public Vsystem {
    VerilatedVcdC _tfp;
    size_t _t;
public:
    explicit tester(const std::string &fn) : _t{ 0 } {
        trace(&_tfp, 114514);
        _tfp.open(fn.c_str());
        clk_i = 1;
        eval();
        _tfp.dump(_t++);
    }

    ~tester() {
        final();
        _tfp.close();
    }

    void tick() {
        clk_i = 0;
        eval();
        _tfp.dump(_t++);
        clk_i = 1;
        eval();
        _tfp.dump(_t++);
    }
};

auto &operator<<(std::ostream &os, const tester &tb) {
    os << (tb.btn_load_o ? "LOAD" : "----") << " ";
    os << (tb.btn_look_o ? "LOOK" : "----") << " ";
    os << (tb.btn_step_o ? "STEP" : "----") << " ";
    os << (tb.btn_run_o ? "RUN" : "---") << " ";
    os << (tb.btn_enter_o ? "ENTER" : "-----") << " ";
    os << (tb.btn_stop_o ? "STOP" : "----") << " ";
    os << (tb.btn_reset_o ? "RESET" : "-----") << " ";
    os << "  ";
    os << (tb.led_power_o ? "POWER" : "-----") << " ";
    os << "  ";
    os << (tb.led_inwait_o ? "INWAIT" : "------") << " ";
    os << (tb.led_ready_o ? "READY" : "-----") << std::endl;
    os << std::setfill('0') << std::setw(2) << std::right << std::hex << static_cast<int>(tb.sw_addr_o) << "   ";
    os << std::setfill('0') << std::setw(4) << std::right << std::hex << static_cast<int>(tb.sw_data_o) << "   ";
    if (tb.stdout_val_o)
        os << std::setfill('0') << std::setw(4) << std::right << std::hex << static_cast<int>(tb.stdout_data_o);
    else
        os << "----";
    os << std::endl;
    return os;
}

int main(int argc, char** argv, char** env) {
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);
    tester tb{"build/dump.vcd"};
    while (!std::cin.eof()) {
        for (size_t i{ 0 }; i < 10ull; i++) {
            tb.tick();
        }
        std::cout << tb;
        std::string str;
        std::cin >> str;
        if (str == "load" || str == "l") {
            tb.btn_load_i = 1;
            tb.tick();
            tb.btn_load_i = 0;
            continue;
        }
        if (str == "look" || str == "k") {
            tb.btn_look_i = 1;
            tb.tick();
            tb.btn_look_i = 0;
            continue;
        }
        if (str == "step" || str == "s") {
            tb.btn_step_i = 1;
            tb.tick();
            tb.btn_step_i = 0;
            continue;
        }
        if (str == "run" || str == "r") {
            tb.btn_run_i = 1;
            tb.tick();
            tb.btn_run_i = 0;
            continue;
        }
        if (str == "enter" || str == "e") {
            tb.btn_enter_i = 1;
            tb.tick();
            tb.btn_enter_i = 0;
            continue;
        }
        if (str == "stop" || str == "x") {
            tb.btn_stop_i = 1;
            tb.tick();
            tb.btn_stop_i = 0;
            continue;
        }
        if (str == "reset" || str == "R") {
            tb.btn_reset_i = 1;
            tb.tick();
            tb.btn_reset_i = 0;
            continue;
        }
        if (str.empty()) {
            continue;
        }
        if (str.size() == 2) {
            tb.sw_addr_i = std::stoi(str, 0, 16);
            continue;
        }
        if (str.size() == 4) {
            tb.sw_data_i = std::stoi(str, 0, 16);
            continue;
        }
        std::cout << "Warning: invalid input" << std::endl;
    }
}
