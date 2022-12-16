`include "constants.v"

module Register(
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,

    // connect with dispatcher
    // data update
    input wire enable_from_dispatcher,
    input wire[`REG_TYPE ] reg_id_from_dispatcher,
    input wire[`ROB_TYPE ] rob_id_from_dispatcher,
    // query react
    input wire[`REG_TYPE ] rs1_from_dispatcher,
    input wire[`REG_TYPE ] rs2_from_dispatcher,
    output wire[`DATA_TYPE ] V1_to_dispatcher,
    output wire[`DATA_TYPE ] V2_to_dispatcher,
    output wire[`ROB_TYPE ] Q1_to_dispatcher,
    output wire[`ROB_TYPE ] Q2_to_dispatcher,

    // connect with reorderbuffer
    input wire enable_from_rob,
    input wire[`DATA_TYPE ] data_from_rob,
    input wire[`REG_TYPE ] addr_from_rob,

    // info from cdb
    input wire commit_flag_from_cdb,
    input wire[`REG_TYPE ] rd_from_cdb,
    input wire[`DATA_TYPE ] V_from_cdb,
    input wire[`ROB_TYPE ] Q_from_cdb,
    input wire rollback_flag_from_cdb
);
    integer i;

    reg[`DATA_TYPE ] registers[`REG_SIZE -1:0];
    reg[`ROB_TYPE ] rob_register[`REG_SIZE -1:0];

    reg roll_back_flag_from_cdb_backup, rob_free;
    reg[`ROB_TYPE ] rob_id_from_dispatcher_backup;
    reg[`REG_TYPE ] reg_id_from_dispatcher_backup;
    reg[`REG_TYPE ] rd_from_cdb_backup;
    reg[`DATA_TYPE ] V_from_cdb_backup;

    assign V1_to_dispatcher = (rd_from_cdb_backup == rs1_from_dispatcher) ? V_from_cdb_backup:registers[rs1_from_dispatcher];
    assign V2_to_dispatcher = (rd_from_cdb_backup == rs2_from_dispatcher) ? V_from_cdb_backup:registers[rs2_from_dispatcher];
    assign Q1_to_dispatcher = (rd_from_cdb_backup == rs1_from_dispatcher && rob_free) ?`ROB_RESET :(reg_id_from_dispatcher_backup == rs1_from_dispatcher ? rob_id_from_dispatcher_backup : (roll_back_flag_from_cdb_backup ?`ROB_RESET : rob_register[rs1_from_dispatcher]));
    assign Q2_to_dispatcher = (rd_from_cdb_backup == rs2_from_dispatcher && rob_free) ?`ROB_RESET :(reg_id_from_dispatcher_backup == rs2_from_dispatcher ? rob_id_from_dispatcher_backup : (roll_back_flag_from_cdb_backup ?`ROB_RESET : rob_register[rs2_from_dispatcher]));


    always @(*) begin
        if (rollback_flag_from_cdb) begin
            roll_back_flag_from_cdb_backup = rollback_flag_from_cdb;
        end
        else begin
            roll_back_flag_from_cdb_backup = `FALSE;
            if (enable_from_dispatcher && reg_id_from_dispatcher != `REG_RESET) begin
                reg_id_from_dispatcher_backup = reg_id_from_dispatcher;
                rob_id_from_dispatcher_backup = rob_id_from_dispatcher;
            end else begin
                reg_id_from_dispatcher_backup = `REG_RESET;
                rob_id_from_dispatcher_backup = `ROB_RESET;
            end
        end
        if (commit_flag_from_cdb) begin
            if (rd_from_cdb != `REG_RESET) begin
                rd_from_cdb_backup = rd_from_cdb;
                V_from_cdb_backup = V_from_cdb;
                if (enable_from_dispatcher && (reg_id_from_dispatcher == rd_from_cdb)) begin
                    if ((rob_id_from_dispatcher_backup == Q_from_cdb)) begin
                        rob_free = `TRUE;
                    end else begin
                        rob_free = `FALSE;
                    end
                end else if (rob_register[rd_from_cdb] == Q_from_cdb) begin
                    rob_free <= `TRUE;
                end else begin
                    rob_free = `FALSE;
                end
            end else begin
                rob_free = `FALSE;
                rd_from_cdb_backup = `REG_RESET;
                V_from_cdb_backup = `DATA_RESET;
            end
        end

    end

    always @(posedge clk_in) begin
        if (rst_in) begin
            for (i = 0; i < `REG_SIZE;i = i+1) begin
                registers[i] <= `REG_RESET;
                rob_register[i] <= `ROB_RESET;
            end
        end
        else begin
            if (rdy_in) begin
                if (roll_back_flag_from_cdb_backup) begin
                    for (i = 0; i < `REG_SIZE;i = i+1) begin
                        rob_register[i] <= `ROB_RESET;
                    end
                end else if (reg_id_from_dispatcher_backup != `REG_RESET) begin
                    rob_register[reg_id_from_dispatcher_backup] <= rob_id_from_dispatcher_backup;
                end
                if (rd_from_cdb_backup != `REG_RESET) begin
                    registers[rd_from_cdb_backup] <= V_from_cdb_backup;
                    if (rob_free) begin
                        rob_register[rd_from_cdb_backup] <= `ROB_RESET;
                    end
                end
            end
            else begin
            end
        end

    end

endmodule