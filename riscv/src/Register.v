`include "constants.v"

module Register(
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,

    // connect with dispatcher
    // data update
    input wire enable_from_dispatcher,
    input wire[`REG_TYPE ] reg_id_from_dispatcher,
    input wire[`ROB_ID_TYPE ] rob_id_from_dispatcher,
    // query react
    input wire[`REG_TYPE ] rs1_from_dispatcher,
    input wire[`REG_TYPE ] rs2_from_dispatcher,
    output wire[`DATA_TYPE ] V1_to_dispatcher,
    output wire[`DATA_TYPE ] V2_to_dispatcher,
    output wire[`ROB_ID_TYPE ] Q1_to_dispatcher,
    output wire[`ROB_ID_TYPE ] Q2_to_dispatcher,

    // connect with reorderbuffer
    input wire[`REG_TYPE ] rd_from_rob,
    input wire[`DATA_TYPE ] V_from_rob,
    input wire[`ROB_ID_TYPE ] Q_from_rob,

    // info from cdb
    input wire commit_flag_from_cdb,
    input wire rollback_flag_from_cdb,

    // dbg
    input wire[`ADDR_TYPE ] dbg_commit_pos_from_rob
);
    integer i;

    reg[`DATA_TYPE ] registers[`REG_SIZE -1:0];
    reg[`ROB_ID_TYPE ] rob_register[`REG_SIZE -1:0];

    reg rollback_flag_from_cdb_backup, rob_free;
    reg[`ROB_ID_TYPE ] rob_id_from_dispatcher_backup;
    reg[`REG_TYPE ] reg_id_from_dispatcher_backup;
    reg[`REG_TYPE ] rd_from_rob_backup;
    reg[`DATA_TYPE ] V_from_rob_backup;

    assign V1_to_dispatcher = (rd_from_rob_backup == rs1_from_dispatcher) ? V_from_rob_backup:registers[rs1_from_dispatcher];
    assign V2_to_dispatcher = (rd_from_rob_backup == rs2_from_dispatcher) ? V_from_rob_backup:registers[rs2_from_dispatcher];
    assign Q1_to_dispatcher = (rd_from_rob_backup == rs1_from_dispatcher && rob_free) ?`ROB_ID_RESET :(reg_id_from_dispatcher_backup == rs1_from_dispatcher ? rob_id_from_dispatcher_backup : (rollback_flag_from_cdb_backup ?`ROB_ID_RESET : rob_register[rs1_from_dispatcher]));
    assign Q2_to_dispatcher = (rd_from_rob_backup == rs2_from_dispatcher && rob_free) ?`ROB_ID_RESET :(reg_id_from_dispatcher_backup == rs2_from_dispatcher ? rob_id_from_dispatcher_backup : (rollback_flag_from_cdb_backup ?`ROB_ID_RESET : rob_register[rs2_from_dispatcher]));


    reg[`DATA_TYPE ] dbg_commit_cnt;


    always @(*) begin
        if (rollback_flag_from_cdb) begin
            rollback_flag_from_cdb_backup = rollback_flag_from_cdb;
        end else begin
            rollback_flag_from_cdb_backup = `FALSE;
            if (enable_from_dispatcher && reg_id_from_dispatcher != `REG_RESET) begin
                reg_id_from_dispatcher_backup = reg_id_from_dispatcher;
                rob_id_from_dispatcher_backup = rob_id_from_dispatcher;
            end else begin
                reg_id_from_dispatcher_backup = `REG_RESET;
                rob_id_from_dispatcher_backup = `ROB_ID_RESET;
            end
        end
        if (commit_flag_from_cdb) begin
            if (rd_from_rob != `REG_RESET) begin
                rd_from_rob_backup = rd_from_rob;
                V_from_rob_backup = V_from_rob;
                if (enable_from_dispatcher && (reg_id_from_dispatcher == rd_from_rob)) begin
                    if ((rob_id_from_dispatcher_backup == Q_from_rob)) begin
                        rob_free = `TRUE;
                    end else begin
                        rob_free = `FALSE;
                    end
                end else if (rob_register[rd_from_rob] == Q_from_rob) begin
                    rob_free = `TRUE;
                end else begin
                    rob_free = `FALSE;
                end
            end else begin
                rob_free = `FALSE;
                rd_from_rob_backup = `REG_RESET;
                V_from_rob_backup = `DATA_RESET;
            end
        end

    end

    always @(posedge clk_in) begin
        if (rst_in) begin
            rollback_flag_from_cdb_backup <= `FALSE;
            rob_free <= `FALSE;
            rob_id_from_dispatcher_backup <= `ROB_ID_RESET;
            reg_id_from_dispatcher_backup <= `REG_RESET;
            rd_from_rob_backup <= `REG_RESET;
            V_from_rob_backup <= `DATA_RESET;
            for (i = 0; i < `REG_SIZE;i = i+1) begin
                registers[i] <= `REG_RESET;
                rob_register[i] <= `ROB_ID_RESET;
            end


            dbg_commit_cnt <= `DATA_RESET;
        end
        else begin
            if (rdy_in) begin
                if (rollback_flag_from_cdb_backup) begin
                    for (i = 0; i < `REG_SIZE;i = i+1) begin
                        rob_register[i] <= `ROB_RESET;
                    end
                end else if (reg_id_from_dispatcher_backup != `REG_RESET) begin
                    rob_register[reg_id_from_dispatcher_backup] <= rob_id_from_dispatcher_backup;
                end
                if (rd_from_rob_backup != `REG_RESET) begin
                    registers[rd_from_rob_backup] <= V_from_rob_backup;
                    if (rob_free) begin
                        rob_register[rd_from_rob_backup] <= `ROB_ID_RESET;
                    end
                end


                if (commit_flag_from_cdb) begin
                    if (dbg_commit_cnt >= 32'h200 && dbg_commit_cnt <= 32'h500) begin
                        $display("commiting, commit_cnt = %h, pc = %h", dbg_commit_cnt, dbg_commit_pos_from_rob);
                        // for (i = 0; i < `REG_SIZE;i = i+1) begin
                        //     $display("reg %h : %h", i, registers[i]);
                        // end
                    end
                    dbg_commit_cnt <= dbg_commit_cnt+1;
                end

            end
            else begin
            end
        end

    end

endmodule