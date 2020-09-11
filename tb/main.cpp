#include "Vsystem.h"
#include "verilated.h"

class tester : public Vsystem {
public:
    tester() {
        clk_i = 1;
        eval();
    }

    void tick() {
        clk_i = 0;
        eval();
        clk_i = 1;
        eval();
    }
};

int main(int argc, char** argv, char** env) {
    Verilated::commandArgs(argc, argv);
    tester tb;
    for (size_t i{ 0 }; i < 1000000ull; i++) {
        tb.tick();
    }
}
