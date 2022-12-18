`include "constants.v"

module ReservationStation(
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,

    // connect with dispatcher
    input wire enable_from_dispatcher,
    input wire[`OP_ENUM_TYPE ] op_enum_from_dispatcher,
    input wire[`DATA_TYPE ] V1_from_dispatcher,
    input wire[`DATA_TYPE ] V2_from_dispatcher,
    input wire[`DATA_TYPE ] imm_from_dispatcher,
    input wire[`ROB_TYPE ] Q1_from_dispatcher,
    input wire[`ROB_TYPE ] Q2_from_dispatcher,
    input wire[`ADDR_TYPE ] inst_pos_from_dispatcher,
    input wire[`ROB_TYPE ] rob_id_from_dispatcher,
    output wire is_full_to_dispatcher,

    // connect with ALU
    output reg[`OP_ENUM_TYPE ] op_enum_to_alu,
    output reg[`DATA_TYPE ] V1_to_alu,
    output reg[`DATA_TYPE ] V2_to_alu,
    output reg[`DATA_TYPE ] imm_to_alu,
    output reg[`ADDR_TYPE ] inst_pos_to_alu,
    input wire busy_from_alu,

    // boardcast to cdb
    output reg [`ROB_TYPE ]rob_id_exec_now_to_cdb,

    // info from cdb broadcast
    input wire enable_from_alu,
    input wire[`ROB_TYPE ] rob_id_from_rs,
    input wire[`DATA_TYPE ] result_from_alu,
    input wire enable_from_lsu,
    input wire[`ROB_TYPE ] rob_id_from_lsb,
    input wire[`DATA_TYPE ] data_from_lsu,


    // connect with reorder buffer
    input wire rollback_flag_from_rob
);

    integer i;

    reg busy[`RS_SIZE -1:0];
    reg[`ADDR_TYPE ] inst_pos[`RS_SIZE -1:0];
    reg[`OP_ENUM_TYPE ] op_enum[`RS_SIZE -1:0];
    reg[`DATA_TYPE ] V1[`RS_SIZE -1:0];
    reg[`DATA_TYPE ] V2[`RS_SIZE -1:0];
    reg[`DATA_TYPE ] imm[`RS_SIZE -1:0];
    reg[`ROB_TYPE ] Q1[`RS_SIZE -1:0];
    reg[`ROB_TYPE ] Q2[`RS_SIZE -1:0];
    reg[`ROB_TYPE ] rob_id[`RS_SIZE -1:0];

    wire[`RS_TYPE ] aviliable_now;
    wire[`RS_TYPE ] exec_now;
    wire is_full = (aviliable_now == `RS_OUT_OF_RANGE);

    wire[`ROB_TYPE ] Q1_insert = (enable_from_alu && Q1_from_dispatcher == rob_id_from_rs) ? `ROB_RESET :((enable_from_lsu && Q1_from_dispatcher == rob_id_from_lsb) ?`ROB_RESET :Q1_from_dispatcher);
    wire[`ROB_TYPE ] Q2_insert = (enable_from_alu && Q2_from_dispatcher == rob_id_from_rs) ? `ROB_RESET :((enable_from_lsu && Q2_from_dispatcher == rob_id_from_lsb) ?`ROB_RESET :Q2_from_dispatcher);
    wire[`DATA_TYPE ] V1_insert = (enable_from_alu && Q1_from_dispatcher == rob_id_from_rs) ? result_from_alu:((enable_from_lsu && Q1_from_dispatcher == rob_id_from_lsb) ? data_from_lsu:V1_from_dispatcher);
    wire[`DATA_TYPE ] V2_insert = (enable_from_alu && Q2_from_dispatcher == rob_id_from_rs) ? result_from_alu:((enable_from_lsu && Q2_from_dispatcher == rob_id_from_lsb) ? data_from_lsu:V2_from_dispatcher);

    assign aviliable_now = ~busy[0] ? 0 :
        (~busy[1] ? 1 :
            (~busy[2] ? 2 :
                (~busy[3] ? 3 :
                    (~busy[4] ? 4 :
                        (~busy[5] ? 5 :
                            (~busy[6] ? 6 :
                                (~busy[7] ? 7 :
                                    (~busy[8] ? 8 :
                                        (~busy[9] ? 9 :
                                            (~busy[10] ? 10 :
                                                (~busy[11] ? 11 :
                                                    (~busy[12] ? 12 :
                                                        (~busy[13] ? 13 :
                                                            (~busy[14] ? 14 :
                                                                (~busy[15] ? 15 :
                                                                `RS_OUT_OF_RANGE)))))))))))))));

    assign exec_now = (busy[0] && Q1[0] == `ROB_RESET && Q2[0] == `ROB_RESET) ? 0:
        ((busy[1] && Q1[1] == `ROB_RESET && Q2[1] == `ROB_RESET) ? 1:
            ((busy[2] && Q1[2] == `ROB_RESET && Q2[2] == `ROB_RESET) ? 2:
                ((busy[3] && Q1[3] == `ROB_RESET && Q2[3] == `ROB_RESET) ? 3:
                    ((busy[4] && Q1[4] == `ROB_RESET && Q2[4] == `ROB_RESET) ? 4:
                        ((busy[5] && Q1[5] == `ROB_RESET && Q2[5] == `ROB_RESET) ? 5:
                            ((busy[6] && Q1[6] == `ROB_RESET && Q2[6] == `ROB_RESET) ? 6:
                                ((busy[7] && Q1[7] == `ROB_RESET && Q2[7] == `ROB_RESET) ? 7:
                                    ((busy[8] && Q1[8] == `ROB_RESET && Q2[8] == `ROB_RESET) ? 8:
                                        ((busy[9] && Q1[9] == `ROB_RESET && Q2[9] == `ROB_RESET) ? 9:
                                            ((busy[10] && Q1[10] == `ROB_RESET && Q2[10] == `ROB_RESET) ? 10:
                                                ((busy[11] && Q1[11] == `ROB_RESET && Q2[11] == `ROB_RESET) ? 11:
                                                    ((busy[12] && Q1[12] == `ROB_RESET && Q2[12] == `ROB_RESET) ? 12:
                                                        ((busy[13] && Q1[13] == `ROB_RESET && Q2[13] == `ROB_RESET) ? 13:
                                                            ((busy[14] && Q1[14] == `ROB_RESET && Q2[14] == `ROB_RESET) ? 14:
                                                                ((busy[15] && Q1[15] == `ROB_RESET && Q2[15] == `ROB_RESET) ? 15:
                                                                `RS_OUT_OF_RANGE)))))))))))))));


    assign is_full_to_dispatcher = is_full;

    always @(posedge clk_in) begin
        if (rst_in || rollback_flag_from_rob) begin
            for (i = 0; i < `RS_SIZE;i = i+1) begin
                busy[i] <= `FALSE;
                inst_pos[i] <= `ADDR_RESET;
                op_enum[i] <= `OP_ENUM_RESET;
                V1[i] <= `DATA_RESET;
                V2[i] <= `DATA_RESET;
                imm[i] <= `DATA_RESET;
                Q1[i] <= `ROB_RESET;
                Q2[i] <= `ROB_RESET;
                rob_id[i] <= `ROB_RESET;
            end
        end
        else if (rdy_in) begin
            // execute
            if (exec_now == `RS_OUT_OF_RANGE) begin
                op_enum_to_alu <= `OP_ENUM_RESET;
            end else begin
                op_enum_to_alu <= op_enum[exec_now];
                V1_to_alu <= V1[exec_now];
                V2_to_alu <= V2[exec_now];
                inst_pos_to_alu <= inst_pos[exec_now];
                imm_to_alu <= imm[exec_now];
                busy[exec_now] <= `FALSE;

                rob_id_exec_now_to_cdb <= rob_id[exec_now];
            end
            // update
            if (enable_from_dispatcher && aviliable_now != `RS_OUT_OF_RANGE) begin // add new inst
                busy[aviliable_now] <= `TRUE;
                op_enum[aviliable_now] <= op_enum_from_dispatcher;
                Q1[aviliable_now] <= Q1_insert;
                Q2[aviliable_now] <= Q2_insert;
                V1[aviliable_now] <= V1_insert;
                V2[aviliable_now] <= V2_insert;
                imm[aviliable_now] <= imm_from_dispatcher;
                inst_pos[aviliable_now] <= inst_pos_from_dispatcher;
                rob_id[aviliable_now] <= rob_id_from_dispatcher;
            end
            if (enable_from_alu) begin // data from alu
                for (i = 0; i < `RS_SIZE;i = i+1) begin
                    if (Q1[i] == rob_id_from_rs) begin
                        V1[i] <= result_from_alu;
                        Q1[i] <= `ROB_RESET;
                    end
                    if (Q2[i] == rob_id_from_rs) begin
                        V2[i] <= result_from_alu;
                        Q2[i] <= `ROB_RESET;
                    end
                end
            end
            if (enable_from_lsu) begin // data from lsu
                for (i = 0; i < `RS_SIZE;i = i+1) begin
                    if (Q1[i] == rob_id_from_lsb) begin
                        V1[i] <= data_from_lsu;
                        V1[i] <= `ROB_RESET;
                    end
                    if (Q2[i] == rob_id_from_lsb) begin
                        V2[i] <= data_from_lsu;
                        Q2[i] <= `ROB_RESET;
                    end
                end
            end
        end
        else begin
        end
    end

endmodule