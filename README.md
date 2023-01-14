## RISCV-CPU

This is a repository created for ACM-21 Computer Architecture Course.

#### About the project

This is a one-core, no Priviledged Instruction Tomasulo CPU in verilog,  on RISCV-I isa. And implemented to FPGA boards.

The CPU has 2K icache, 16 reservation station, 16 load store buffer and 32 reorder buffer, alone with 512 local biomodal branch predictor.

#### Prediction success rate

| test case   | predict count | rollback count | success rate |
| ----------- | ------------- | -------------- | ------------ |
| array_test1 | 138           | 34             | 75.36%       |
| array_test2 | 146           | 33             | 77.40%       |
| expr        | 4215          | 558            | 86.76%       |
| looper      | 1705          | 228            | 88.63%       |
| gcd         | 583           | 132            | 77.36%       |
| lvalue2     | 1             | 1              | 0%           |
| multiarray  | 2812          | 727            | 74.15%       |
| hanoi       | 27105         | 3445           | 87.39%       |
| magic       | 141459        | 20951          | 85.19%       |

