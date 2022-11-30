`include "constants.v"

module ReservationStation(
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,

    // connect with dispatcher
    input wire enable_from_dispatcher,
    input wire[`DATA_TYPE ] V1_from_dispatcher,
    input wire[`DATA_TYPE ] V2_from_dispatcher,
    input wire[`DATA_TYPE ] imm_from_dispatcher,
    input wire[`ROB_TYPE ] Q1_from_dispatcher,
    input wire[`ROB_TYPE ] Q2_from_dispatcher,
    input wire[`ADDR_TYPE ] inst_pos_from_dispatcher,
    input wire[`ROB_TYPE ] rob_id_from_dispatcher,


);

    integer i;

    reg busy[`RS_SIZE -1:0];
    reg[`ADDR_TYPE ] inst_pos[`RS_SIZE -1:0];
    reg[`OP_ENUM_TYPE ] op_enum[`RS_SIZE -1:0];
    reg[`DATA_TYPE ] v1[`RS_SIZE -1:0];
    reg[`DATA_TYPE ] v2[`RS_SIZE -1:0];
    reg[`DATA_TYPE ] imm[`RS_SIZE -1:0];
    reg[`ROB_TYPE ] Q1[`RS_SIZE -1:0];
    reg[`ROB_TYPE ] Q2[`RS_SIZE -1:0];
    reg[`ROB_TYPE ] rob_id[`RS_SIZE -1:0];


endmodule