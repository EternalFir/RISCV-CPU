//`include "D:\SJTU\上课\计算机系统（1）\CPU\RISCV-CPU\riscv\src\constants.v"
`include "constants.v"

module Predictor(
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,

    // connect with Fetcher
    // input wire enable_from_fetcher,
    input wire[`ADDR_TYPE ] pc_from_fetcher,
    input wire[`INST_TYPE ] inst_from_fetcher,
    // output reg end_to_fetcher,
    output wire[`ADDR_TYPE ] imm_to_fetcher,
    output wire jump_predict_flag_to_fetcher,
    output wire is_jalr_inst_to_fetcher,
    // output reg undo_flag_to_fetcher,

    // connect with ReorderBuffer
    input wire enable_from_reorderbuffer,
    input wire[`ADDR_TYPE ] inst_addr_from_reorderbuffer,
    input wire jump_result_from_reorderbuffer
    // output reg end_to_reorderbuffer,
    );
    integer i;
    reg[1:0] local_history[`PREDICTOR_SIZE -1:0];
    wire[`DATA_TYPE ] branch_imm = {{20{inst_from_fetcher[31]}}, inst_from_fetcher[7:7], inst_from_fetcher[30:25], inst_from_fetcher[11:8], 1'b0};
    wire[`DATA_TYPE] jal_imm = {{12{inst_from_fetcher[31]}}, inst_from_fetcher[19:12], inst_from_fetcher[20], inst_from_fetcher[30:21], 1'b0};

    assign jump_predict_flag_to_fetcher = (inst_from_fetcher[`OPCODE_RANGE ] == `OPCODE_JAL) ? `TRUE :
        ((inst_from_fetcher[`OPCODE_RANGE ] == `OPCODE_BRANCH) ? local_history[pc_from_fetcher[8:0]] [1]:`FALSE);

    assign imm_to_fetcher = (inst_from_fetcher[`OPCODE_RANGE ] == `OPCODE_JAL) ? jal_imm:branch_imm;

    assign is_jalr_inst_to_fetcher = (inst_from_fetcher[`OPCODE_RANGE ] == `OPCODE_JALR) ? `TRUE :`FALSE;



    always @(posedge clk_in) begin
        if (rst_in) begin
            for (i = 0; i < `PREDICTOR_SIZE; i = i+1) begin
                local_history[i] <= 1;
            end
        end else if (rdy_in) begin
            if (enable_from_reorderbuffer) begin
                if (jump_result_from_reorderbuffer) begin
                    if (local_history[inst_addr_from_reorderbuffer[8:0]] < 3) begin
                        local_history[inst_addr_from_reorderbuffer[8:0]] <= local_history[inst_addr_from_reorderbuffer[8:0]]+1;
                    end
                end else begin
                    if (local_history[inst_addr_from_reorderbuffer[8:0]] > 0) begin
                        local_history[inst_addr_from_reorderbuffer[8:0]] <= local_history[inst_addr_from_reorderbuffer[8:0]]-1;
                    end
                end
            end
        end
    end

endmodule
