`include "constants.v"
`include "Decoder.v"

module Dispatcher(
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,

    // connect with fetcher
    input wire end_from_fetcher,
    input wire [`INST_TYPE ]inst_from_fetcher,
    input wire [`ADDR_TYPE ] inst_pos_from_fetcher,
    input wire if_jump_flag_predicted_from_fetcher,
    input wire [`ADDR_TYPE ] roll_back_pos_from_fetcher,
    output reg enable_to_fetcher,

    // connect with reorder buffer
    //about if_rdy ask
    input wire if_Q1_rdy_from_rob,
    input wire[`DATA_TYPE ] Q1_data_from_rob,
    input wire if_Q2_rdy_from_rob,
    input wire [`DATA_TYPE ] Q2_data_from_rob,
    output wire [`ROB_TYPE ]Q1_to_rob,
    output wire [`ROB_TYPE ]Q2_to_rob,
    // about inst add
    input wire[`ROB_TYPE ]rob_id_from_rob,
    output reg enable_to_rob,
    output reg is_load_flag_to_rob,
    output reg is_jump_flag_to_rob,
    output reg if_jump_predicted_to_rob,
    output reg[`ADDR_TYPE ]inst_pos_to_rob,
    output reg [`ADDR_TYPE ]roll_back_pos_to_rob,

    // conenect with register


    // connect with reservation station

    // connect with load store buffer

    // info from cdb

);

endmodule : Dispatcher