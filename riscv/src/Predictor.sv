`include "constants.sv"
module Predictor(
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,

    // connect with Fetcher
    input wire enable_from_fetcher,
    input wire [`ADDR_TYPE ] pc_from_fetcher,
    output reg end_to_predictor,
    output reg [`ADDR_TYPE ] address_to_fetcher,
    output reg jump_predict_flag_to_fetcher,
    output reg undo_flag_to_fetcher,
)



endmodule
