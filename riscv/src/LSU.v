`include "constants.v"
module LSU(
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,

    // connection with lsb
    input wire enable_from_lsb,
    input wire read_write_falg_from_lsb,
    input wire[`OP_ENUM_TYPE ] op_enum_from_lsb,
    input wire[`ADDR_TYPE ] object_address_from_lsb,
    input wire[`DATA_TYPE ] data_from_lsb,
    output reg busy_to_lsb,
    output reg end_to_lsb,
    output reg[`DATA_TYPE ] data_to_lsb,

    // connect wiith memcontrol
    input wire end_from_memcont,
    input wire[`DATA_TYPE ] data_from_memcont,
    input wire aviliable_from_memcont,
    output reg enable_to_memcont,
    output wire read_write_flag_to_memcont, // 1 for read, 0 for write
    output wire[`ADDR_TYPE ] address_to_memcont,
    output reg[`DATA_TYPE ] data_to_memcont,

    // boardcast
    output reg enable_to_cdb,
    output reg[`DATA_TYPE ] result_to_cdb,

    // connect with reorder buffer
    input wire rollback_flag_from_rob
);

    // assign busy_to_lsb = (enable_from_lsb || !end_to_lsb);
    assign read_write_flag_to_memcont = read_write_falg_from_lsb;
    assign address_to_memcont = object_address_from_lsb;

    reg dbg_visited_object_ram;
    reg dbg_is_write;


    always @(posedge clk_in) begin
        if (rst_in) begin
            enable_to_memcont <= `FALSE;
            end_to_lsb <= `FALSE;
            busy_to_lsb <= `FALSE;
            enable_to_cdb <= `FALSE;


            dbg_visited_object_ram <= `FALSE;
            dbg_is_write <= `FALSE;
        end
        else if (rdy_in) begin

            if (object_address_from_lsb == 32'h00001264) begin
                dbg_visited_object_ram <= `TRUE;
                if (read_write_falg_from_lsb == `WRITE_SIT)
                    dbg_is_write <= `TRUE;
                else
                    dbg_is_write <= `FALSE;
            end else begin
                dbg_visited_object_ram<=`FALSE ;
            end


            enable_to_cdb <= `FALSE;
            if (enable_from_lsb && !busy_to_lsb) begin // begin
                busy_to_lsb <= `TRUE;
                enable_to_memcont <= `TRUE;
                case (op_enum_from_lsb)
                    `OP_ENUM_LB : begin
                end
                    `OP_ENUM_LH: begin

                end
                    `OP_ENUM_LW: begin

                end
                    `OP_ENUM_LBU: begin

                end
                    `OP_ENUM_LHU: begin

                end
                    `OP_ENUM_SB: begin
                    data_to_memcont <= {{24{data_from_lsb[7]}}, data_from_lsb[7:0]};
                end
                `OP_ENUM_SH: begin
                    data_to_memcont <= {{16{data_from_lsb[15]}}, data_from_lsb[15:0]};
                end
                `OP_ENUM_SW: begin
                    data_to_memcont <= data_from_lsb;
                end
                endcase
            end
            if (end_from_memcont && enable_to_memcont) begin // finish
                enable_to_memcont <= `FALSE;
                busy_to_lsb <= `FALSE;
                end_to_lsb <= `TRUE;
                case (op_enum_from_lsb)
                    `OP_ENUM_LB : begin
                    data_to_lsb <= {{24{data_from_memcont[7]}}, data_from_memcont[7:0]};
                    enable_to_cdb <= `TRUE;
                    result_to_cdb <= {{24{data_from_memcont[7]}}, data_from_memcont[7:0]};
                end
                `OP_ENUM_LH: begin
                    data_to_lsb <= {{16{data_from_memcont[15]}}, data_from_memcont[15:0]};
                    enable_to_cdb <= `TRUE;
                    result_to_cdb <= {{16{data_from_memcont[15]}}, data_from_memcont[15:0]};
                end
                `OP_ENUM_LW: begin
                    data_to_lsb <= data_from_memcont;
                    enable_to_cdb <= `TRUE;
                    // result_to_cdb <= {{16{data_from_memcont[15]}}, data_from_memcont[15:0]};
                    result_to_cdb<=data_from_memcont;
                end
                `OP_ENUM_LBU: begin
                    data_to_lsb <= `DATA_RESET +{data_from_memcont[7:0]};
                    enable_to_cdb <= `TRUE;
                    result_to_cdb <= `DATA_RESET +{data_from_memcont[7:0]};
                end
                `OP_ENUM_LHU: begin
                    data_to_lsb <= `DATA_RESET +{data_from_memcont[15:0]};
                    enable_to_cdb <= `TRUE;
                    result_to_cdb <= `DATA_RESET +{data_from_memcont[15:0]};
                end
                `OP_ENUM_SB: begin
                    enable_to_cdb <= `FALSE;
                end
                `OP_ENUM_SH: begin
                    enable_to_cdb <= `FALSE;
                end
                `OP_ENUM_SW: begin
                    enable_to_cdb <= `FALSE;
                end
                endcase
            end else begin
                end_to_lsb <= `FALSE;
            end
            // if (enable_from_lsb) begin
            //     if (end_to_lsb) begin
            //         enable_to_memcont <= `TRUE;
            //     end
            //     if (aviliable_from_memcont && end_to_lsb) begin // first time
            //         enable_to_memcont <= `TRUE;
            //         end_to_lsb <= `FALSE;
            //         case (op_enum_from_lsb)
            //             `OP_ENUM_LB : begin
            //         end
            //             `OP_ENUM_LH: begin
            //
            //         end
            //             `OP_ENUM_LW: begin
            //
            //         end
            //             `OP_ENUM_LBU: begin
            //
            //         end
            //             `OP_ENUM_LHU: begin
            //
            //         end
            //             `OP_ENUM_SB: begin
            //             data_to_memcont <= {{24{data_from_lsb[7]}}, data_from_lsb[7:0]};
            //         end
            //         `OP_ENUM_SH: begin
            //             data_to_memcont <= {{16{data_from_lsb[15]}}, data_from_lsb[15:0]};
            //         end
            //         `OP_ENUM_SW: begin
            //             data_to_memcont <= data_from_lsb;
            //         end
            //         endcase
            //     end
            //     if (end_from_memcont && !end_to_lsb) begin // finish with memcont
            //         enable_to_memcont <= `FALSE;
            //         end_to_lsb <= `TRUE;
            //         case (op_enum_from_lsb)
            //             `OP_ENUM_LB : begin
            //             data_to_lsb <= {{24{data_from_memcont[7]}}, data_from_memcont[7:0]};
            //             enable_to_cdb <= `TRUE;
            //             result_to_cdb <= {{24{data_from_memcont[7]}}, data_from_memcont[7:0]};
            //         end
            //         `OP_ENUM_LH: begin
            //             data_to_lsb <= {{16{data_from_memcont[15]}}, data_from_memcont[15:0]};
            //             enable_to_cdb <= `TRUE;
            //             result_to_cdb <= {{16{data_from_memcont[15]}}, data_from_memcont[15:0]};
            //         end
            //         `OP_ENUM_LW: begin
            //             data_to_lsb <= data_from_memcont;
            //             enable_to_cdb <= `TRUE;
            //             result_to_cdb <= {{16{data_from_memcont[15]}}, data_from_memcont[15:0]};
            //         end
            //         `OP_ENUM_LBU: begin
            //             data_to_lsb <= `DATA_RESET +{data_from_memcont[7:0]};
            //             enable_to_cdb <= `TRUE;
            //             result_to_cdb <= `DATA_RESET +{data_from_memcont[7:0]};
            //         end
            //         `OP_ENUM_LHU: begin
            //             data_to_lsb <= `DATA_RESET +{data_from_memcont[15:0]};
            //             enable_to_cdb <= `TRUE;
            //             result_to_cdb <= `DATA_RESET +{data_from_memcont[15:0]};
            //         end
            //         `OP_ENUM_SB: begin
            //             enable_to_cdb <= `FALSE;
            //         end
            //         `OP_ENUM_SH: begin
            //             enable_to_cdb <= `FALSE;
            //         end
            //         `OP_ENUM_SW: begin
            //             enable_to_cdb <= `FALSE;
            //         end
            //         endcase
            //     end else begin
            //         enable_to_cdb <= `FALSE;
            //     end
            // end
        end
        else begin

        end
    end

endmodule