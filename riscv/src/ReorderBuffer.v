`include "constants.v"

module ReorderBuffer(
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,

    // connect with dispatcher
    // about if_reday ask
    input wire[`ROB_TYPE ] Q1_from_dispatcher,
    input wire[`ROB_TYPE ] Q2_from_dispatcher,
    output wire if_Q1_rdy_to_dispatcher,
    output wire[`DATA_TYPE ] Q1_data_to_dispatcher,
    output wire if_Q2_rdy_to_dispatcher,
    output wire[`DATA_TYPE ] Q2_data_to_dispatcher,
    // about inst add
    input wire enable_from_dispatcher,
    input wire is_load_flag_from_dispatcher,
    input wire is_jump_flag_from_dispatcher,
    // input wire[`REG_TYPE ] rd_from_dispatcher,
    input wire if_jump_predicted_from_dispatcher,
    input wire[`ADDR_TYPE ] inst_pos_from_dispatcher,
    input wire[`ADDR_TYPE ] rollback_pos_from_dispatcher,
    output wire[`ROB_TYPE ] rob_id_to_dispatcher,

    // connect with rs


    // connect with register

    // connect with predictor
    output reg enable_to_predictor,
    output reg jump_result_to_predictor,
    output reg[`ADDR_TYPE ] inst_pos_to_predictor,

);

endmodule