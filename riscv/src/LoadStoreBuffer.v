`include "constants.v"

module LoadStoreBuffer(
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,

    // connect with dispatcher
    input wire enable_from_dispatcher,
    input wire[`OP_ENUM_TYPE ] op_enum_from_dispatcehr,
    input wire[`DATA_TYPE ] V1_from_dispatcher,
    input wire[`DATA_TYPE ] V2_from_dispatcher,
    input wire[`DATA_TYPE ] imm_from_dispatcher,
    input wire[`ROB_TYPE ] Q1_from_dispatcher,
    input wire[`ROB_TYPE ] Q2_from_dispatcher,
    input wire[`ADDR_TYPE ] inst_pos_from_dispatcher,
    input wire[`ROB_TYPE ] rob_id_from_dispatcher,
    output wire full_flag_to_dispatcher,

    // connect with lsu
    input wire busy_from_lsu,
    input wire end_from_lsu,
    input wire[`DATA_TYPE ] data_from_lsu,
    output reg enable_to_lsu,
    output reg read_write_flag_to_lsu,
    output reg[`OP_ENUM_TYPE ] op_enum_to_lsu,
    output reg[`ADDR_TYPE ] object_address_to_lsu,
    output reg[`DATA_TYPE ] data_to_lsu,

    // info from cdb broadcast
    input wire enable_from_alu,
    input wire[`ROB_TYPE ] rob_id_from_alu,
    input wire[`DATA_TYPE ] result_from_alu,
    input wire enable_from_lsu,
    input wire[`ROB_TYPE ] rob_id_from_lsu,
    input wire[`DATA_TYPE ] result_from_lsu,

    // connect with rob
    input wire roll_back_flag_from_rob

);

    reg busy[`LSB_SIZE -1:0];
    reg[`OP_ENUM_TYPE ] op_enum[`LSB_SIZE -1:0];
    reg[`DATA_TYPE ] V1[`LSB_SIZE -1:0];
    reg[`DATA_TYPE ] V2[`LSB_SIZE -1:0];
    reg[`DATA_TYPE ] imm[`LSB_SIZE -1:0];
    reg[`ROB_TYPE ] Q1[`LSB_SIZE -1:0];
    reg[`ROB_TYPE ] Q2[`LSB_SIZE -1:0];
    reg[`ROB_TYPE ] rob_id[`LSB_SIZE -1:0];
    reg committed[`LSB_SIZE -1:0];

    reg[`LSB_TYPE ] head, tail, commit_tail;
    reg[`ROB_TYPE ] element_num;
    wire full = element_num >= (`LSB_SIZE -`FULL_PRESERVE);

    assign full_flag_to_dispatcher = full;

    integer i;

    always @(posedge clk_in) begin
        if (rst_in ||(roll_back_flag_from_rob && commit_tail == `LSB_OUT_OF_RANGE ))begin
        element_num <= `ROB_RESET;

        end
    end



endmodule