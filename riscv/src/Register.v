`include "constants.v"

module Register(
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,

    // connect with dispatcher
    input wire[`REG_TYPE ] addr_from_dispatcher,
    output wire[`DATA_TYPE ] data_to_dispatcher,

    // connect with reorderbuffer
    input wire enable_from_rob,
    input wire[`DATA_TYPE ] data_from_rob,
    input wire[`REG_TYPE ] addr_from_rob,

);
    integer i;

    reg[`DATA_TYPE ] registers[`REG_SIZE  -1:0];

    always @(*) begin
        assign data_to_dispatcher = registers[addr_from_dispatcher];
    end

    always @(posedge clk_in) begin
        if (rst_in) begin
            for (i = 0; i < `REG_NUM;i = i+1) begin
                registers[i] <= `REG_RESET;
            end
        end
        if (enable_from_rob) begin
            registers[addr_from_rob] <= data_from_rob;
        end
    end

endmodule : Register