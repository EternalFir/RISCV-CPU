// RISCV32I CPU top module
// port modification allowed for debugging purposes

`include "constants.v"

// `include "MemoryControl.v"
// `include "Fetcher.v"
// `include "Predictor.v"
// `include "Dispatcher.v"
// `include "Register.v"
// `include "ReservationStation.v"
// `include "ALU.v"
// `include "LoadStoreBuffer.v"
// `include "LSU.v"
// `include "ReorderBuffer.v"

module cpu(
    input wire clk_in,            // system clock signal
    input wire rst_in,            // reset signal
    input wire rdy_in,            // ready signal, pause cpu when low

    input wire[7:0] mem_din,        // data input bus
    output wire[7:0] mem_dout,        // data output bus
    output wire[31:0] mem_a,            // address bus (only 17:0 is used)
    output wire mem_wr,            // write/read signal (1 for write)

    input wire io_buffer_full, // 1 if uart buffer is full

    output wire[31:0] dbgreg_dout        // cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read result will be returned in the next cycle. Write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)

    // connection between reorder buffer and dispatcher
    wire[`ROB_ID_TYPE ] Q1_from_dispatcher_to_rob;
    wire[`ROB_ID_TYPE ] Q2_from_dispatcher_to_rob;
    wire if_Q1_rdy_from_rob_to_dispatcher;
    wire[`DATA_TYPE ] Q1_data_from_rob_to_dispatcher;
    wire if_Q2_rdy_from_rob_to_dispatcher;
    wire[`DATA_TYPE ] Q2_data_from_rob_to_dispatcher;
    wire enable_from_dispatcher_to_rob;
    wire[`REG_TYPE ] rd_from_dispatcher_to_rob;
    wire is_load_flag_from_dispatcher_to_rob;
    wire is_store_flag_from_dispatcher_to_rob;
    wire is_jump_from_dispatcher_to_rob;
    wire is_jalr_from_dispatcher_to_rob;
    wire if_jump_predicted_from_dispatcher_to_rob;
    wire[`ADDR_TYPE ] inst_pos_from_dispatcher_to_rob;
    wire[`ADDR_TYPE ] rollback_pos_from_dispatcher_to_rob;
    wire[`ROB_ID_TYPE ] rob_id_from_rob_to_dispatcher;

    // connection between reorder buffer and load store buffer
    wire[`ROB_ID_TYPE ] io_rob_id_from_lsb_to_rob;
    wire[`ROB_ID_TYPE ] rob_id_from_rob_to_lsb;
    wire[`ROB_ID_TYPE ] head_io_rob_id_from_rob_to_lsb;

    // connection between reorder buffer and register
    wire[`REG_TYPE ] rd_from_rob_to_register;
    wire[`DATA_TYPE ] V_from_rob_to_register;
    wire[`ROB_ID_TYPE ] Q_from_rob_to_register;

    // connection between reorder buffer and predictor
    wire enable_from_rob_to_predictor;
    wire jump_result_from_rob_to_predictor;
    wire[`ADDR_TYPE ] inst_pos_from_rob_to_predictor;

    // connection between reorder buffer and fetcher
    wire[`ADDR_TYPE ] target_pc_pos_from_rob_to_fetcher;
    wire is_jalr_commit_from_rob_to_fetcher;

    // rob broadcast to cdb
    wire rollback_flag_from_rob_to_cdb;
    wire commit_flag_from_rob_to_cdb;
    wire full_from_rob_to_cdb;

    // connection between memory control and fetcher
    wire enable_from_fetcher_to_memcont;
    wire[`ADDR_TYPE ] address_from_fetcher_to_memcont;
    // wire reset_from_fetcher_to_memcont;
    wire end_from_memcont_to_fetcher;
    wire one_inst_finish_from_memcont_to_fetcher;
    wire[`INST_TYPE ] inst_from_memcont_to_fetcher;

    // connection between memory control and lsu
    wire enable_from_lsu_to_memcont;
    wire read_write_flag_from_lsu_to_memcont;
    wire[`ADDR_TYPE ] address_from_lsu_to_memcont;
    wire[`DATA_TYPE ] data_from_lsu_to_memcont;
    wire end_from_memcont_to_lsu;
    wire[`DATA_TYPE ] data_from_memcont_to_lsu;

    // memory control broadcast
    wire aviliable_from_memcont;

    // connection between fetcher and predictor
    wire[`ADDR_TYPE ] imm_from_predictor_to_fetcher;
    wire jump_predict_flag_from_predictor_to_fetcher;
    wire is_jalr_inst_from_predictor_to_fetcher;
    wire[`ADDR_TYPE ] pc_from_fetcher_to_predictor;
    wire[`INST_TYPE ] inst_from_fetcher_to_predictor;

    // connection between fetcher and dispatcher
    wire idle_from_fetcher_to_dispatcher;
    wire[`INST_TYPE ] inst_from_fetcher_to_dispatcher;
    wire[`ADDR_TYPE ] inst_pos_from_fetcher_to_dispatcher;
    wire if_jump_flag_predicted_from_fetcher_to_dispatcher;
    wire[`ADDR_TYPE ] rollback_pos_from_fetcher_to_dispatcher;

    // connection between dispatcher and register
    wire enable_from_dispatcher_to_register;
    wire[`REG_TYPE ] reg_id_from_dispatcher_to_register;
    wire[`ROB_ID_TYPE ] rob_id_from_dispatcher_to_register;
    wire[`REG_TYPE ] rs1_from_dispatcher_to_register;
    wire[`REG_TYPE ] rs2_from_dispatcher_to_register;
    wire[`DATA_TYPE ] V1_from_register_to_dispatcher;
    wire[`DATA_TYPE ] V2_from_register_to_dispatcher;
    wire[`ROB_ID_TYPE ] Q1_from_register_to_dispatcher;
    wire[`ROB_ID_TYPE ] Q2_from_register_to_dispatcher;

    // connection between dispatcher and reservation station
    wire enable_from_dispatcher_to_rs;
    wire[`OP_ENUM_TYPE ] op_enum_from_dispatcher_to_rs;
    wire[`DATA_TYPE ] V1_from_dispatcher_to_rs;
    wire[`DATA_TYPE ] V2_from_dispatcher_to_rs;
    wire[`DATA_TYPE ] imm_from_dispatcher_to_rs;
    wire[`ROB_ID_TYPE ] Q1_from_dispatcher_to_rs;
    wire[`ROB_ID_TYPE ] Q2_from_dispatcher_to_rs;
    wire[`ADDR_TYPE ] inst_pos_from_dispatcher_to_rs;
    wire[`ROB_ID_TYPE ] rob_id_from_dispatcher_to_rs;
    wire is_full_from_rs_to_dispatcher;

    // connection between dispatcher and load store buffer
    wire enable_from_dispatcher_to_lsb;
    wire[`OP_ENUM_TYPE ] op_enum_from_dispatcher_to_lsb;
    wire[`DATA_TYPE ] V1_from_dispatcher_to_lsb;
    wire[`DATA_TYPE ] V2_from_dispatcher_to_lsb;
    wire[`DATA_TYPE ] imm_from_dispatcher_to_lsb;
    wire[`ROB_ID_TYPE ] Q1_from_dispatcher_to_lsb;
    wire[`ROB_ID_TYPE ] Q2_from_dispatcher_to_lsb;
    wire[`ADDR_TYPE ] inst_pos_from_dispatcher_to_lsb;
    wire[`ROB_ID_TYPE ] rob_id_from_dispatcher_to_lsb;
    wire full_flag_from_lsb_to_dispatcher;

    // connection between reservation station and alu
    wire[`OP_ENUM_TYPE ] op_enum_from_rs_to_alu;
    wire[`DATA_TYPE ] V1_from_rs_to_alu;
    wire[`DATA_TYPE ] V2_from_rs_to_alu;
    wire[`DATA_TYPE ] imm_from_rs_to_alu;
    wire[`ADDR_TYPE ] inst_pos_from_rs_to_alu;
    wire busy_from_alu_to_rs;

    // reservation station broadcast to cdb
    wire[`ROB_ID_TYPE ] rob_id_enec_now_from_rs_to_cdb;

    // alu broadcast to cdb
    wire enable_from_alu_to_cdb;
    wire jump_flag_from_alu_to_cdb;
    wire[`DATA_TYPE ] result_from_alu_to_cdb;
    wire[`ADDR_TYPE ] target_pos_from_alu_to_cdb;

    // connection between load store buffer and lsu
    wire busy_from_lsu_to_lsb;
    wire end_from_lsu_to_lsb;
    wire[`DATA_TYPE ] data_from_lsu_to_lsb;
    wire enable_from_lsb_to_lsu;
    wire read_write_flag_from_lsb_to_lsu;
    wire[`OP_ENUM_TYPE ] op_enum_from_lsb_to_lsu;
    wire[`ADDR_TYPE ] object_address_from_lsb_to_lsu;
    wire[`DATA_TYPE ] data_from_lsb_to_lsu;

    // lsb broadcast to cdb
    wire[`ROB_ID_TYPE ] rob_id_from_lsb_to_cdb;

    // lsu broadcast to cdb
    wire enable_from_lsu_to_cdb;
    wire[`DATA_TYPE ] result_from_lsu_to_cdb;

    // global full
    wire global_full = (is_full_from_rs_to_dispatcher || full_flag_from_lsb_to_dispatcher || full_from_rob_to_cdb);

    // dbg
    // wire [`ADDR_TYPE ]dbg_commit_pos_from_rob_to_register;
// modules:

    ReorderBuffer reorderBuffer(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .rdy_in(rdy_in),

        // connect with dispatcher
        .Q1_from_dispatcher(Q1_from_dispatcher_to_rob),
        .Q2_from_dispatcher(Q2_from_dispatcher_to_rob),
        .if_Q1_rdy_to_dispatcher(if_Q1_rdy_from_rob_to_dispatcher),
        .Q1_data_to_dispatcher(Q1_data_from_rob_to_dispatcher),
        .if_Q2_rdy_to_dispatcher(if_Q2_rdy_from_rob_to_dispatcher),
        .Q2_data_to_dispatcher(Q2_data_from_rob_to_dispatcher),
        .enable_from_dispatcher(enable_from_dispatcher_to_rob),
        .rd_from_dispatcher(rd_from_dispatcher_to_rob),
        .is_load_flag_from_dispatcher(is_load_flag_from_dispatcher_to_rob),
        .is_store_flag_from_dispatcher(is_store_flag_from_dispatcher_to_rob),
        .is_jump_from_dispatcher(is_jump_from_dispatcher_to_rob),
        .is_jalr_from_dispatcher(is_jalr_from_dispatcher_to_rob),
        .if_jump_predicted_from_dispatcher(if_jump_predicted_from_dispatcher_to_rob),
        .inst_pos_from_dispatcher(inst_pos_from_dispatcher_to_rob),
        .rollback_pos_from_dispatcher(rollback_pos_from_dispatcher_to_rob),
        .rob_id_to_dispatcher(rob_id_from_rob_to_dispatcher),

        // connect with lsb
        .io_rob_id_from_lsb(io_rob_id_from_lsb_to_rob),
        .rob_id_to_lsb(rob_id_from_rob_to_lsb),
        .head_io_rob_id_to_lsb(head_io_rob_id_from_rob_to_lsb),

        // connect with register
        .rd_to_register(rd_from_rob_to_register),
        .V_to_register(V_from_rob_to_register),
        .Q_to_register(Q_from_rob_to_register),

        // connect with predictor
        .enable_to_predictor(enable_from_rob_to_predictor),
        .jump_result_to_predictor(jump_result_from_rob_to_predictor),
        .inst_pos_to_predictor(inst_pos_from_rob_to_predictor),

        // connect with fetcher
        .target_pc_pos_to_fetcher(target_pc_pos_from_rob_to_fetcher),
        .is_jalr_commit_to_fetcher(is_jalr_commit_from_rob_to_fetcher),

        // info fom cdb
        .enable_from_alu(enable_from_alu_to_cdb),
        .jump_flag_from_alu(jump_flag_from_alu_to_cdb),
        .rob_id_from_rs(rob_id_enec_now_from_rs_to_cdb),
        .result_from_alu(result_from_alu_to_cdb),
        .target_pos_from_alu(target_pos_from_alu_to_cdb),
        .enable_from_lsu(enable_from_lsu_to_cdb),
        .rob_id_from_lsb(rob_id_from_lsb_to_cdb),
        .result_from_lsu(result_from_lsu_to_cdb),

        // broadcast
        .rollback_flag(rollback_flag_from_rob_to_cdb),
        .commit_flag(commit_flag_from_rob_to_cdb),
        .full_to_cdb(full_from_rob_to_cdb)

        // dbg
        // .dbg_commit_pos_to_register(dbg_commit_pos_from_rob_to_register)
    );

    MemoryControl memoryControl(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .rdy_in(rdy_in),

        // connect with ram
        .read_write_flag_to_ram(mem_wr),
        .address_to_ram(mem_a),
        .data_to_ram(mem_dout),
        .data_from_ram(mem_din),

        // connect with fetcher
        .enable_from_fetcher(enable_from_fetcher_to_memcont),
        .addrress_from_fetcher(address_from_fetcher_to_memcont),
        // .reset_from_fetcher(reset_from_fetcher_to_memcont),
        .end_to_fetcher(end_from_memcont_to_fetcher),
        .one_inst_finish_to_fetcher(one_inst_finish_from_memcont_to_fetcher),
        .inst_to_fetcher(inst_from_memcont_to_fetcher),

        // connect with lsu
        .enable_from_lsu(enable_from_lsu_to_memcont),
        .read_wirte_flag_from_lsu(read_write_flag_from_lsu_to_memcont),
        .address_from_lsu(address_from_lsu_to_memcont),
        .data_from_lsu(data_from_lsu_to_memcont),
        .end_to_lsu(end_from_memcont_to_lsu),
        .data_to_lsu(data_from_memcont_to_lsu),

        // broad cast to fetcher and lsu
        .aviliable(aviliable_from_memcont),

        // io buffer full signal
        .io_buffer_full(io_buffer_full)
    );

    Fetcher fetcher(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .rdy_in(rdy_in),

        // connect with memory control
        .end_from_memcont(end_from_memcont_to_fetcher),
        .one_inst_finish_from_momcont(one_inst_finish_from_memcont_to_fetcher),
        .inst_from_memcont(inst_from_memcont_to_fetcher),
        .aviliable_from_memcont(aviliable_from_memcont),
        .enable_to_memcont(enable_from_fetcher_to_memcont),
        .address_to_memcont(address_from_fetcher_to_memcont),
        // .reset_to_memcont(reset_from_fetcher_to_memcont),

        // connect with predictor
        .imm_from_predictor(imm_from_predictor_to_fetcher),
        .jump_predict_flag_from_predictor(jump_predict_flag_from_predictor_to_fetcher),
        .is_jalr_inst_from_predictor(is_jalr_inst_from_predictor_to_fetcher),
        .pc_to_predictor(pc_from_fetcher_to_predictor),
        .inst_to_predictor(inst_from_fetcher_to_predictor),

        // connect with despatcher
        .idle_to_dispatcher(idle_from_fetcher_to_dispatcher),
        .inst_to_dispatcher(inst_from_fetcher_to_dispatcher),
        .inst_pos_to_dispatcher(inst_pos_from_fetcher_to_dispatcher),
        .if_jump_flag_predicted_to_dispatcher(if_jump_flag_predicted_from_fetcher_to_dispatcher),
        .rollback_pos_to_dispatcher(rollback_pos_from_fetcher_to_dispatcher),

        // connect with reorder buffer
        .targer_pc_pos_from_rob(target_pc_pos_from_rob_to_fetcher),
        .is_jalr_commit_from_rob(is_jalr_commit_from_rob_to_fetcher),

        // info from cdb
        .rollback_flag_from_rob(rollback_flag_from_rob_to_cdb),
        .full_flag_in(global_full)
    );

    Dispatcher dispatcher(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .rdy_in(rdy_in),

        // connect with fetcher
        .idle_from_fetcher(idle_from_fetcher_to_dispatcher),
        .inst_from_fetcher(inst_from_fetcher_to_dispatcher),
        .inst_pos_from_fetcher(inst_pos_from_fetcher_to_dispatcher),
        .if_jump_flag_predicted_from_fetcher(if_jump_flag_predicted_from_fetcher_to_dispatcher),
        .rollback_pos_from_fetcher(rollback_pos_from_fetcher_to_dispatcher),

        // connect with reorder buffer
        .if_Q1_rdy_from_rob(if_Q1_rdy_from_rob_to_dispatcher),
        .data1_from_rob(Q1_data_from_rob_to_dispatcher),
        .if_Q2_rdy_from_rob(if_Q2_rdy_from_rob_to_dispatcher),
        .data2_from_rob(Q2_data_from_rob_to_dispatcher),
        .Q1_to_rob(Q1_from_dispatcher_to_rob),
        .Q2_to_rob(Q2_from_dispatcher_to_rob),
        .rob_id_from_rob(rob_id_from_rob_to_dispatcher),
        .enable_to_rob(enable_from_dispatcher_to_rob),
        .rd_to_rob(rd_from_dispatcher_to_rob),
        .is_load_to_rob(is_load_flag_from_dispatcher_to_rob),
        .is_store_to_rob(is_store_flag_from_dispatcher_to_rob),
        .is_jump_to_rob(is_jump_from_dispatcher_to_rob),
        .is_jalr_to_rob(is_jalr_from_dispatcher_to_rob),
        .if_jump_predicted_to_rob(if_jump_predicted_from_dispatcher_to_rob),
        .inst_pos_to_rob(inst_pos_from_dispatcher_to_rob),
        .rollback_pos_to_rob(rollback_pos_from_dispatcher_to_rob),

        // connect with register
        .enable_to_register(enable_from_dispatcher_to_register),
        .reg_id_to_register(reg_id_from_dispatcher_to_register),
        .rob_id_to_register(rob_id_from_dispatcher_to_register),
        .rs1_to_register(rs1_from_dispatcher_to_register),
        .rs2_to_register(rs2_from_dispatcher_to_register),
        .V1_from_register(V1_from_register_to_dispatcher),
        .V2_from_register(V2_from_register_to_dispatcher),
        .Q1_from_register(Q1_from_register_to_dispatcher),
        .Q2_from_register(Q2_from_register_to_dispatcher),

        // connect with reservation station
        .enable_to_rs(enable_from_dispatcher_to_rs),
        .op_enum_to_rs(op_enum_from_dispatcher_to_rs),
        .V1_to_rs(V1_from_dispatcher_to_rs),
        .V2_to_rs(V2_from_dispatcher_to_rs),
        .imm_to_rs(imm_from_dispatcher_to_rs),
        .Q1_to_rs(Q1_from_dispatcher_to_rs),
        .Q2_to_rs(Q2_from_dispatcher_to_rs),
        .inst_pos_to_rs(inst_pos_from_dispatcher_to_rs),
        .rob_id_to_rs(rob_id_from_dispatcher_to_rs),
        .is_full_from_rs(is_full_from_rs_to_dispatcher),

        // connect with load store buffer
        .enable_to_lsb(enable_from_dispatcher_to_lsb),
        .op_enum_to_lsb(op_enum_from_dispatcher_to_lsb),
        .V1_to_lsb(V1_from_dispatcher_to_lsb),
        .V2_to_lsb(V2_from_dispatcher_to_lsb),
        .imm_to_lsb(imm_from_dispatcher_to_lsb),
        .Q1_to_lsb(Q1_from_dispatcher_to_lsb),
        .Q2_to_lsb(Q2_from_dispatcher_to_lsb),
        .inst_pos_to_lsb(inst_pos_from_dispatcher_to_lsb),
        .rob_id_to_lsb(rob_id_from_dispatcher_to_lsb),
        .full_flag_from_lsb(full_flag_from_lsb_to_dispatcher),

        // info from cdb
        .enable_from_alu(enable_from_alu_to_cdb),
        .rob_id_from_rs(rob_id_enec_now_from_rs_to_cdb),
        .result_from_alu(result_from_alu_to_cdb),
        .enable_from_lsu(enable_from_lsu_to_cdb),
        .rob_id_from_lsb(rob_id_from_lsb_to_cdb),
        .result_from_lsu(result_from_lsu_to_cdb),

        // connect with rob
        .rollback_flag_from_rob(rollback_flag_from_rob_to_cdb)
    );

    Predictor predictor(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .rdy_in(rdy_in),

        // connect with fetcher
        .pc_from_fetcher(pc_from_fetcher_to_predictor),
        .inst_from_fetcher(inst_from_fetcher_to_predictor),
        .imm_to_fetcher(imm_from_predictor_to_fetcher),
        .jump_predict_flag_to_fetcher(jump_predict_flag_from_predictor_to_fetcher),
        .is_jalr_inst_to_fetcher(is_jalr_inst_from_predictor_to_fetcher),

        // connect with reorder buffer
        .enable_from_reorderbuffer(enable_from_rob_to_predictor),
        .inst_addr_from_reorderbuffer(inst_pos_from_rob_to_predictor),
        .jump_result_from_reorderbuffer(jump_result_from_rob_to_predictor)
    );

    ReservationStation reservationStation(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .rdy_in(rdy_in),

        // connection with dispatcher
        .enable_from_dispatcher(enable_from_dispatcher_to_rs),
        .op_enum_from_dispatcher(op_enum_from_dispatcher_to_rs),
        .V1_from_dispatcher(V1_from_dispatcher_to_rs),
        .V2_from_dispatcher(V2_from_dispatcher_to_rs),
        .imm_from_dispatcher(imm_from_dispatcher_to_rs),
        .Q1_from_dispatcher(Q1_from_dispatcher_to_rs),
        .Q2_from_dispatcher(Q2_from_dispatcher_to_rs),
        .inst_pos_from_dispatcher(inst_pos_from_dispatcher_to_rs),
        .rob_id_from_dispatcher(rob_id_from_dispatcher_to_rs),
        .is_full_to_dispatcher(is_full_from_rs_to_dispatcher),

        // connect with alu
        .op_enum_to_alu(op_enum_from_rs_to_alu),
        .V1_to_alu(V1_from_rs_to_alu),
        .V2_to_alu(V2_from_rs_to_alu),
        .imm_to_alu(imm_from_rs_to_alu),
        .inst_pos_to_alu(inst_pos_from_rs_to_alu),
        .busy_from_alu(busy_from_alu_to_rs),

        // broadcast
        .rob_id_exec_now_to_cdb(rob_id_enec_now_from_rs_to_cdb),

        // info from cdb
        .enable_from_alu(enable_from_alu_to_cdb),
        .rob_id_from_rs(rob_id_enec_now_from_rs_to_cdb),
        .result_from_alu(result_from_alu_to_cdb),
        .enable_from_lsu(enable_from_lsu_to_cdb),
        .rob_id_from_lsb(rob_id_from_lsb_to_cdb),
        .data_from_lsu(result_from_lsu_to_cdb),

        // connect with reorder buffer
        .rollback_flag_from_rob(rollback_flag_from_rob_to_cdb)
    );

    ALU aLU(
        // connect with reservation station
        .op_enum(op_enum_from_rs_to_alu),
        .V1(V1_from_rs_to_alu),
        .V2(V2_from_rs_to_alu),
        .imm(imm_from_rs_to_alu),
        .inst_pos(inst_pos_from_rs_to_alu),

        // broadcast
        .enable(enable_from_alu_to_cdb),
        .jump_flag(jump_flag_from_alu_to_cdb),
        .result(result_from_alu_to_cdb),
        .target_pos(target_pos_from_alu_to_cdb)
    );

    LoadStoreBuffer loadStoreBuffer(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .rdy_in(rdy_in),

        // connect with dispatcher
        .enable_from_dispatcher(enable_from_dispatcher_to_lsb),
        .op_enum_from_dispatcher(op_enum_from_dispatcher_to_lsb),
        .V1_from_dispatcher(V1_from_dispatcher_to_lsb),
        .V2_from_dispatcher(V2_from_dispatcher_to_lsb),
        .imm_from_dispatcher(imm_from_dispatcher_to_lsb),
        .Q1_from_dispatcher(Q1_from_dispatcher_to_lsb),
        .Q2_from_dispatcher(Q2_from_dispatcher_to_lsb),
        .inst_pos_from_dispatcher(inst_pos_from_dispatcher_to_lsb),
        .rob_id_from_dispatcher(rob_id_from_dispatcher_to_lsb),
        .full_flag_to_dispatcher(full_flag_from_lsb_to_dispatcher),

        // connect with lsu
        .busy_from_lsu(busy_from_lsu_to_lsb),
        .end_from_lsu(end_from_lsu_to_lsb),
        .data_from_lsu(data_from_lsu_to_lsb),
        .enable_to_lsu(enable_from_lsb_to_lsu),
        .read_write_flag_to_lsu(read_write_flag_from_lsb_to_lsu),
        .op_enum_to_lsu(op_enum_from_lsb_to_lsu),
        .object_address_to_lsu(object_address_from_lsb_to_lsu),
        .data_to_lsu(data_from_lsb_to_lsu),

        // info from broadcast
        .enable_from_alu(enable_from_alu_to_cdb),
        .rob_id_from_rs(rob_id_enec_now_from_rs_to_cdb),
        .result_from_alu(result_from_alu_to_cdb),
        .enable_from_lsu(enable_from_lsu_to_cdb),
        .rob_id_from_lsb(rob_id_from_lsb_to_cdb),
        .result_from_lsu(result_from_lsu_to_cdb),

        // broadcast
        .rob_id_to_cdb(rob_id_from_lsb_to_cdb),

        // connect with rob
        .commit_flag_from_rob(commit_flag_from_rob_to_cdb),
        .rob_id_from_rob(rob_id_from_rob_to_lsb),
        .head_io_rob_id_from_rob(head_io_rob_id_from_rob_to_lsb),
        .io_rob_id_to_rob(io_rob_id_from_lsb_to_rob),
        .roll_back_flag_from_rob(rollback_flag_from_rob_to_cdb)
    );

    LSU lSU(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .rdy_in(rdy_in),

        // connect with load store buffer
        .enable_from_lsb(enable_from_lsb_to_lsu),
        .read_write_falg_from_lsb(read_write_flag_from_lsb_to_lsu),
        .op_enum_from_lsb(op_enum_from_lsb_to_lsu),
        .object_address_from_lsb(object_address_from_lsb_to_lsu),
        .data_from_lsb(data_from_lsb_to_lsu),
        .busy_to_lsb(busy_from_lsu_to_lsb),
        .end_to_lsb(end_from_lsu_to_lsb),
        .data_to_lsb(data_from_lsu_to_lsb),

        // connect with memory control
        .end_from_memcont(end_from_memcont_to_lsu),
        .data_from_memcont(data_from_memcont_to_lsu),
        .aviliable_from_memcont(aviliable_from_memcont),
        .enable_to_memcont(enable_from_lsu_to_memcont),
        .read_write_flag_to_memcont(read_write_flag_from_lsu_to_memcont),
        .address_to_memcont(address_from_lsu_to_memcont),
        .data_to_memcont(data_from_lsu_to_memcont),

        // broadcast
        .enable_to_cdb(enable_from_lsu_to_cdb),
        .result_to_cdb(result_from_lsu_to_cdb),

        // connect with reorder buffer
        .rollback_flag_from_rob(rollback_flag_from_rob_to_cdb)
    );

    Register register(
        .clk_in(clk_in),
        .rst_in(rst_in),
        .rdy_in(rdy_in),

        // connect with dispatcher
        .enable_from_dispatcher(enable_from_dispatcher_to_register),
        .reg_id_from_dispatcher(reg_id_from_dispatcher_to_register),
        .rob_id_from_dispatcher(rob_id_from_dispatcher_to_register),
        .rs1_from_dispatcher(rs1_from_dispatcher_to_register),
        .rs2_from_dispatcher(rs2_from_dispatcher_to_register),
        .V1_to_dispatcher(V1_from_register_to_dispatcher),
        .V2_to_dispatcher(V2_from_register_to_dispatcher),
        .Q1_to_dispatcher(Q1_from_register_to_dispatcher),
        .Q2_to_dispatcher(Q2_from_register_to_dispatcher),

        // connect with reorder buffer
        .rd_from_rob(rd_from_rob_to_register),
        .V_from_rob(V_from_rob_to_register),
        .Q_from_rob(Q_from_rob_to_register),

        // info from cdb
        .commit_flag_from_cdb(commit_flag_from_rob_to_cdb),
        .rollback_flag_from_cdb(rollback_flag_from_rob_to_cdb)

        // dbg
        // .dbg_commit_pos_from_rob(dbg_commit_pos_from_rob_to_register)
    );

endmodule