#include "Vour.h"
#include "verilated.h"

int main(int argc, char** argv, char** env) {
    Verilated::commandArgs(argc, argv);
    {
       Vour top;
       while (!Verilated::gotFinish()) {
          top.eval();
       }
    }
}
