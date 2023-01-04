`include "constants.v"
`include "Decoder.v"

module Dispatcher(
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,

    // connect with fetcher
    // input wire end_from_fetcher,
    input wire idle_from_fetcher,
    input wire[`INST_TYPE ] inst_from_fetcher,
    input wire[`ADDR_TYPE ] inst_pos_from_fetcher,
    input wire if_jump_flag_predicted_from_fetcher,
    input wire[`ADDR_TYPE ] rollback_pos_from_fetcher,
    // output reg enable_to_fetcher,

    // connect with reorder buffer
    //about if_rdy ask
    input wire if_Q1_rdy_from_rob,
    input wire[`DATA_TYPE ] data1_from_rob,
    input wire if_Q2_rdy_from_rob,
    input wire[`DATA_TYPE ] data2_from_rob,
    output wire[`ROB_ID_TYPE ] Q1_to_rob,
    output wire[`ROB_ID_TYPE ] Q2_to_rob,
    // about inst add
    input wire[`ROB_ID_TYPE ] rob_id_from_rob,
    output reg enable_to_rob,
    output reg[`REG_TYPE ] rd_to_rob,
    output reg is_load_to_rob,
    output reg is_store_to_rob,
    output reg is_jump_to_rob,
    output reg is_jalr_to_rob,
    output reg if_jump_predicted_to_rob,
    output reg[`ADDR_TYPE ] inst_pos_to_rob,
    output reg[`ADDR_TYPE ] rollback_pos_to_rob,

    // conenect with register
    // about data update
    output reg enable_to_register,
    output reg[`REG_TYPE ] reg_id_to_register,
    output wire[`ROB_ID_TYPE ] rob_id_to_register,
    // about data query
    output wire[`REG_TYPE ] rs1_to_register,
    output wire[`REG_TYPE ] rs2_to_register,
    input wire[`DATA_TYPE ] V1_from_register,
    input wire[`DATA_TYPE ] V2_from_register,
    input wire[`ROB_ID_TYPE ] Q1_from_register,
    input wire[`ROB_ID_TYPE ] Q2_from_register,


    // connect with reservation station
    output reg enable_to_rs,
    output reg[`OP_ENUM_TYPE ] op_enum_to_rs,
    output reg[`DATA_TYPE ] V1_to_rs,
    output reg[`DATA_TYPE ] V2_to_rs,
    output reg[`DATA_TYPE ] imm_to_rs,
    output reg[`ROB_ID_TYPE ] Q1_to_rs,
    output reg[`ROB_ID_TYPE ] Q2_to_rs,
    output reg[`ADDR_TYPE ] inst_pos_to_rs,
    output wire[`ROB_ID_TYPE ] rob_id_to_rs,
    input wire is_full_from_rs,

    // connect with load store buffer
    output reg enable_to_lsb,
    output reg[`OP_ENUM_TYPE ] op_enum_to_lsb,
    output reg[`DATA_TYPE ] V1_to_lsb,
    output reg[`DATA_TYPE ] V2_to_lsb,
    output reg[`DATA_TYPE ] imm_to_lsb,
    output reg[`ROB_ID_TYPE ] Q1_to_lsb,
    output reg[`ROB_ID_TYPE ] Q2_to_lsb,
    output reg [`ADDR_TYPE ] inst_pos_to_lsb,
    output wire[`ROB_ID_TYPE ] rob_id_to_lsb,
    input wire full_flag_from_lsb,

    // info from cdb broadcast
    input wire enable_from_alu,
    input wire[`ROB_ID_TYPE ] rob_id_from_rs,
    input wire[`DATA_TYPE ] result_from_alu,
    input wire enable_from_lsu,
    input wire[`ROB_ID_TYPE ] rob_id_from_lsb,
    input wire[`DATA_TYPE ] result_from_lsu,

    // connect with rob
    input wire rollback_flag_from_rob
);

    // with an inner decoder
    wire[`INST_TYPE ] inst_to_decoder = inst_from_fetcher;
    wire[`OP_ENUM_TYPE ] op_enum_from_decoder;
    wire[`REG_TYPE ] rd_from_decoder;
    wire[`REG_TYPE ] rs1_from_decoder;
    wire[`REG_TYPE ] rs2_from_decoder;
    wire[`DATA_TYPE ] imm_from_decoder;
    wire is_jump_from_decoder;
    wire is_load_from_decoder;
    wire is_store_from_decoder;

    Decoder inner_decoder(
        .inst_in(inst_to_decoder),
        .op_enum(op_enum_from_decoder),
        .rd(rd_from_decoder),
        .rs1(rs1_from_decoder),
        .rs2(rs2_from_decoder),
        .imm(imm_from_decoder),
        .is_jump(is_jump_from_decoder),
        .is_load(is_load_from_decoder),
        .is_store(is_store_from_decoder)
    );

    wire[`ROB_ID_TYPE ] Q1_insert = (enable_from_alu && Q1_from_register == rob_id_from_rs) ? `ROB_ID_RESET :((enable_from_lsu && Q1_from_register == rob_id_from_lsb) ?`ROB_ID_RESET :(if_Q1_rdy_from_rob ? `ROB_ID_RESET : Q1_from_register));
    wire[`ROB_ID_TYPE ] Q2_insert = (enable_from_alu && Q2_from_register == rob_id_from_rs) ? `ROB_ID_RESET :((enable_from_lsu && Q2_from_register == rob_id_from_lsb) ?`ROB_ID_RESET :(if_Q2_rdy_from_rob ?`ROB_ID_RESET : Q2_from_register));
    wire[`DATA_TYPE ] V1_insert = (enable_from_alu && Q1_from_register == rob_id_from_rs) ? result_from_alu:((enable_from_lsu && Q1_from_register == rob_id_from_lsb) ? result_from_lsu:(if_Q1_rdy_from_rob ? data1_from_rob : V1_from_register));
    wire[`DATA_TYPE ] V2_insert = (enable_from_alu && Q2_from_register == rob_id_from_rs) ? result_from_alu:((enable_from_lsu && Q2_from_register == rob_id_from_lsb) ? result_from_lsu:(if_Q2_rdy_from_rob ? data2_from_rob : V2_from_register));

    assign Q1_to_rob = Q1_from_register;
    assign Q2_to_rob = Q2_from_register;
    assign rob_id_to_register = rob_id_from_rob;
    assign rob_id_to_rs = rob_id_from_rob;
    assign rob_id_to_lsb = rob_id_from_rob;
    assign rs1_to_register = rs1_from_decoder;
    assign rs2_to_register = rs2_from_decoder;


    always @(posedge clk_in) begin
        if (rst_in || !rdy_in || op_enum_from_decoder == `OP_ENUM_RESET || !idle_from_fetcher || rollback_flag_from_rob) begin
            enable_to_register <= `FALSE;
            enable_to_rob <= `FALSE;
            enable_to_rs <= `FALSE;
            enable_to_lsb <= `FALSE;
        end
        else begin
            if (idle_from_fetcher) begin
                enable_to_register <= `TRUE;
                enable_to_rob <= `TRUE;
                if (op_enum_from_decoder >= `OP_ENUM_LB && op_enum_from_decoder <= `OP_ENUM_SW) begin // load & store insts
                    enable_to_lsb <= `TRUE;
                    enable_to_rs <= `FALSE;
                end else begin
                    enable_to_rs <= `TRUE;
                    enable_to_lsb <= `FALSE;
                end
            end else begin
                enable_to_register <= `FALSE;
                enable_to_rob <= `FALSE;
                enable_to_rs <= `FALSE;
                enable_to_lsb <= `FALSE;
            end
            // ligature
            // rob
            rd_to_rob <= rd_from_decoder;
            is_load_to_rob <= is_load_from_decoder;
            is_store_to_rob <= is_store_from_decoder;
            is_jump_to_rob <= is_jump_from_decoder;
            is_jalr_to_rob <= (op_enum_from_decoder == `OP_ENUM_JALR) ? `TRUE :`FALSE;
            if_jump_predicted_to_rob <= if_jump_flag_predicted_from_fetcher;
            inst_pos_to_rob <= inst_pos_from_fetcher;
            rollback_pos_to_rob <= rollback_pos_from_fetcher;
            // register
            reg_id_to_register <= rd_from_decoder;
            // rs
            op_enum_to_rs <= op_enum_from_decoder;
            Q1_to_rs <= Q1_insert;
            Q2_to_rs <= Q2_insert;
            imm_to_rs <= imm_from_decoder;
            V1_to_rs <= V1_insert;
            V2_to_rs <= V2_insert;
            inst_pos_to_rs <= inst_pos_from_fetcher;
            // lsb
            op_enum_to_lsb <= op_enum_from_decoder;
            Q1_to_lsb <= Q1_insert;
            Q2_to_lsb <= Q2_insert;
            imm_to_lsb <= imm_from_decoder;
            V1_to_lsb <= V1_insert;
            V2_to_lsb <= V2_insert;
            inst_pos_to_lsb <= inst_pos_from_fetcher;
        end
    end


endmodule