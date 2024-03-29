`include "constants.v"

module ReorderBuffer(
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,

    // connect with dispatcher
    // about if_reday ask
    input wire[`ROB_ID_TYPE ] Q1_from_dispatcher,
    input wire[`ROB_ID_TYPE ] Q2_from_dispatcher,
    output wire if_Q1_rdy_to_dispatcher,
    output wire[`DATA_TYPE ] Q1_data_to_dispatcher,
    output wire if_Q2_rdy_to_dispatcher,
    output wire[`DATA_TYPE ] Q2_data_to_dispatcher,
    // about inst add
    input wire enable_from_dispatcher,
    input wire[`REG_TYPE ] rd_from_dispatcher,
    input wire is_load_flag_from_dispatcher,
    input wire is_store_flag_from_dispatcher,
    input wire is_jump_from_dispatcher,
    input wire is_jalr_from_dispatcher,
    input wire if_jump_predicted_from_dispatcher,
    input wire[`ADDR_TYPE ] inst_pos_from_dispatcher,
    input wire[`ADDR_TYPE ] rollback_pos_from_dispatcher,
    output wire[`ROB_ID_TYPE ] rob_id_to_dispatcher,

    // connect with rs

    // connect with lsb
    input wire[`ROB_ID_TYPE ] io_rob_id_from_lsb,
    output reg[`ROB_ID_TYPE ] rob_id_to_lsb,
    output wire[`ROB_ID_TYPE ] head_io_rob_id_to_lsb,

    // connect with register
    output reg[`REG_TYPE ] rd_to_register,
    output reg[`DATA_TYPE ] V_to_register,
    output reg[`ROB_ID_TYPE ] Q_to_register,

    // connect with predictor
    output reg enable_to_predictor,
    output reg jump_result_to_predictor,
    output reg[`ADDR_TYPE ] inst_pos_to_predictor,

    // connect with fetcher
    output reg[`ADDR_TYPE ] target_pc_pos_to_fetcher,
    output reg is_jalr_commit_to_fetcher,

    // info from cdb broadcast
    input wire enable_from_alu,
    input wire jump_flag_from_alu,
    input wire[`ROB_ID_TYPE ] rob_id_from_rs,
    input wire[`DATA_TYPE ] result_from_alu,
    input wire[`ADDR_TYPE ] target_pos_from_alu,
    input wire enable_from_lsu,
    input wire[`ROB_ID_TYPE ] rob_id_from_lsb,
    input wire[`DATA_TYPE ] result_from_lsu,


    // broadcast 
    output reg rollback_flag,
    output reg commit_flag,
    output wire full_to_cdb,

    // dbg
    output reg[`ADDR_TYPE ] dbg_commit_pos_to_register

);

    // rob data
    reg busy[`ROB_SIZE -1:0];
    reg is_ready[`ROB_SIZE -1:0];
    reg if_jump_predicted[`ROB_SIZE -1:0];
    reg[`REG_TYPE ] rd[`ROB_SIZE -1:0];
    reg[`DATA_TYPE ] data[`ROB_SIZE -1:0];
    reg[`ADDR_TYPE ] inst_pos[`ROB_SIZE -1:0];
    reg if_jump_result[`ROB_SIZE -1:0];
    reg[`ADDR_TYPE ] target_pos[`ROB_SIZE -1:0];
    reg[`ADDR_TYPE ] rollback_pos[`ROB_SIZE -1:0];
    reg is_jump_inst[`ROB_SIZE -1:0];
    reg is_load_inst[`ROB_SIZE -1:0];
    reg is_store_inst[`ROB_SIZE -1:0];
    reg is_jalr_inst[`ROB_SIZE -1:0];
    reg is_io_inst[`ROB_SIZE -1:0];

    reg[`ROB_TYPE ] head;
    reg[`ROB_TYPE ] tail;
    reg[`ROB_TYPE ] element_num;

    wire insert_signal = enable_from_dispatcher;
    wire commit_signal = busy[head] && (is_ready[head] || is_store_inst[head]);

    wire[`ROB_ID_TYPE ] rob_id_rs_1 = (rob_id_from_rs == 6'h00) ? 6'h1f:rob_id_from_rs-1;
    wire[`ROB_ID_TYPE ] rob_id_lsb_1 = (rob_id_from_lsb == 6'h00) ? 6'h1f:rob_id_from_lsb-1;

    integer i;

    assign full_to_cdb = element_num >= (`ROB_SIZE -`FULL_PRESERVE);
    assign rob_id_to_dispatcher = tail+1;
    assign head_io_rob_id_to_lsb = (busy[head] && is_io_inst[head]) ? head+1:`ROB_ID_RESET;

    assign if_Q1_rdy_to_dispatcher = (Q1_from_dispatcher == `ROB_ID_RESET) ?`FALSE :is_ready[Q1_from_dispatcher-1];
    assign if_Q2_rdy_to_dispatcher = (Q2_from_dispatcher == `ROB_ID_RESET) ?`FALSE :is_ready[Q2_from_dispatcher-1];
    assign Q1_data_to_dispatcher = (Q1_from_dispatcher == `ROB_ID_RESET) ? `DATA_RESET :data[Q1_from_dispatcher-1];
    assign Q2_data_to_dispatcher = (Q2_from_dispatcher == `ROB_ID_RESET) ? `DATA_RESET :data[Q2_from_dispatcher-1];

    reg[`ADDR_TYPE ] dbg_commit_inst_pos;
    reg[`DATA_TYPE ] dbg_commit_count = 1;
    reg[`ROB_ID_TYPE ] dbg_rob_ready_now;
    reg[`ROB_ID_TYPE ] dbg_rob_rdy_now_2;
    reg dbg_commit_1f_true;
    reg dbg_commit_1f_false;
    wire dbg_busy_1f = busy[5'h1f];
    wire dbg_0d_ready = is_ready[5'h0d];


    always @(posedge clk_in) begin
        if (rst_in || rollback_flag) begin
            for (i = 0; i < `ROB_SIZE;i = i+1) begin
                busy[i] <= `FALSE;
                is_ready[i] <= `FALSE;
                if_jump_predicted[i] <= `FALSE;
                rd[i] <= `REG_RESET;
                data[i] <= `DATA_RESET;
                inst_pos[i] <= `ADDR_RESET;
                if_jump_result[i] <= `FALSE;
                target_pos[i] <= `ADDR_RESET;
                rollback_pos[i] <= `ADDR_RESET;
                is_jump_inst[i] <= `FALSE;
                is_load_inst[i] <= `FALSE;
                is_store_inst[i] <= `FALSE;
                is_jalr_inst[i] <= `FALSE;
                is_io_inst[i] <= `FALSE;
            end
            head <= `ROB_RESET;
            tail <= `ROB_RESET;
            element_num <= `ROB_RESET;
            enable_to_predictor <= `FALSE;
            rollback_flag <= `FALSE;
            commit_flag <= `FALSE;
            target_pc_pos_to_fetcher <= `ADDR_RESET;


            dbg_commit_inst_pos <= `ADDR_RESET;
            dbg_commit_pos_to_register <= `ADDR_RESET;
            dbg_rob_ready_now <= `ROB_ID_RESET;
            dbg_rob_rdy_now_2 <= `ROB_ID_RESET;
            dbg_commit_1f_true <= `FALSE;
            dbg_commit_1f_false <= `FALSE;
            // dbg_commit_count <= `DATA_RESET;
        end else if (rdy_in) begin
            // calcu the element number
            if ((insert_signal && commit_signal) || (!insert_signal && !commit_signal)) begin
                element_num <= element_num;
            end else if (insert_signal) begin
                element_num <= element_num+1;
            end else if (commit_signal) begin
                element_num <= element_num-1;
            end
            // update with cdb info
            // from rs
            if ((busy[rob_id_rs_1] == `TRUE) && (enable_from_alu == `TRUE)) begin
                is_ready[rob_id_rs_1] <= `TRUE;
                data[rob_id_rs_1] <= result_from_alu;
                target_pos[rob_id_rs_1] <= target_pos_from_alu;
                if_jump_result[rob_id_rs_1] <= jump_flag_from_alu;


                dbg_rob_ready_now <= rob_id_from_rs-1;
                dbg_rob_rdy_now_2 <= (rob_id_from_rs == 6'h00) ? 6'h1f:rob_id_from_rs-1;

                if (rob_id_from_rs == 6'h00) begin
                    dbg_commit_1f_true <= `TRUE;
                end else begin
                    dbg_commit_1f_true <= `FALSE;
                end
            end else begin
                // dbg_commit_1f <= `FALSE;
                dbg_rob_ready_now <= rob_id_from_rs-1;
                if (rob_id_from_rs == 6'h00) begin
                    dbg_commit_1f_false <= `TRUE;
                end else begin
                    dbg_commit_1f_false <= `FALSE;
                end

            end

            // if ((busy[rob_id_from_rs-1] == `TRUE) && (enable_from_alu == `TRUE)) begin
            //     is_ready[rob_id_from_rs-1] <= `TRUE;
            //     data[rob_id_from_rs-1] <= result_from_alu;
            //     target_pos[rob_id_from_rs-1] <= target_pos_from_alu;
            //     if_jump_result[rob_id_from_rs-1] <= jump_flag_from_alu;
            //
            //
            //     dbg_rob_ready_now <= rob_id_from_rs-1;
            //     dbg_rob_rdy_now_2 <= (rob_id_from_rs == 5'h00) ? 5'h1f:rob_id_from_rs-1;
            //
            //     if (rob_id_from_rs == 5'h00) begin
            //         dbg_commit_1f_true <= `TRUE;
            //     end else begin
            //         dbg_commit_1f_true <= `FALSE;
            //     end
            // end else begin
            //     // dbg_commit_1f <= `FALSE;
            //     dbg_rob_ready_now <= rob_id_from_rs-1;
            //     if (rob_id_from_rs == 5'h00) begin
            //         dbg_commit_1f_false <= `TRUE;
            //     end else begin
            //         dbg_commit_1f_false <= `FALSE;
            //     end
            //
            // end


            // from lsb
            if (busy[rob_id_lsb_1] && enable_from_lsu) begin
                is_ready[rob_id_lsb_1] <= `TRUE;
                data[rob_id_lsb_1] <= result_from_lsu;


                dbg_rob_ready_now <= rob_id_from_lsb-1;
            end
            // if (busy[rob_id_from_lsb-1] && enable_from_lsu) begin
            //     is_ready[rob_id_from_lsb-1] <= `TRUE;
            //     data[rob_id_from_lsb-1] <= result_from_lsu;
            //
            //
            //     dbg_rob_ready_now <= rob_id_from_lsb-1;
            // end
            // insert
            if (enable_from_dispatcher) begin
                busy[tail] <= `TRUE;
                is_ready[tail] <= `FALSE;
                if_jump_predicted[tail] <= if_jump_predicted_from_dispatcher;
                rd[tail] <= rd_from_dispatcher;
                data[tail] <= `DATA_RESET;
                inst_pos[tail] <= inst_pos_from_dispatcher;
                if_jump_result[tail] <= `FALSE;
                target_pos[tail] <= `ADDR_RESET;
                rollback_pos[tail] <= rollback_pos_from_dispatcher;
                is_jump_inst[tail] <= is_jump_from_dispatcher;
                is_load_inst[tail] <= is_load_flag_from_dispatcher;
                is_store_inst[tail] <= is_store_flag_from_dispatcher;
                is_jalr_inst[tail] <= is_jalr_from_dispatcher;
                is_io_inst[tail] <= `FALSE;
                tail <= ((tail == `ROB_SIZE-1) ? 0:tail+1);
            end
            // commit
            if (commit_signal) begin
                commit_flag <= `TRUE;
                rd_to_register <= rd[head];
                V_to_register <= data[head];
                Q_to_register <= head+1;
                rob_id_to_lsb <= head+1;
                head <= ((head == `ROB_SIZE-1) ? 0:head+1);


                dbg_commit_pos_to_register <= inst_pos[head];
                // if(dbg_commit_count<=32'h70)begin
                //     $display("commiting, commit_cnt = %h, pc = %h",dbg_commit_count, inst_pos[head]);
                // end

                dbg_commit_inst_pos <= inst_pos[head];
                dbg_commit_count <= dbg_commit_count+1;

                if (is_jump_inst[head]) begin
                    enable_to_predictor <= `TRUE;
                    inst_pos_to_predictor <= inst_pos[head];
                    jump_result_to_predictor <= if_jump_result[head];
                    if (if_jump_predicted[head] != if_jump_result[head]) begin
                        rollback_flag <= `TRUE;
                        target_pc_pos_to_fetcher <= if_jump_result[head] ? target_pos[head] : rollback_pos[head];
                    end else begin
                        rollback_flag <= `FALSE;
                    end
                end else begin
                    enable_to_predictor <= `FALSE;
                    rollback_flag <= `FALSE;
                end
                if (is_jalr_inst[head]) begin
                    is_jalr_commit_to_fetcher <= `TRUE;
                end else begin
                    is_jalr_commit_to_fetcher <= `FALSE;
                end
                busy[head] <= `FALSE;
                is_ready[head] <= `FALSE;
                if_jump_predicted[head] <= `FALSE;
                rd[head] <= `REG_RESET;
                data[head] <= `DATA_RESET;
                inst_pos[head] <= `ADDR_RESET;
                if_jump_result[head] <= `FALSE;
                target_pos[head] <= `ADDR_RESET;
                rollback_pos[head] <= `ADDR_RESET;
                is_jump_inst[head] <= `FALSE;
                is_load_inst[head] <= `FALSE;
                is_store_inst[head] <= `FALSE;
                is_io_inst[head] <= `FALSE;
            end else begin
                commit_flag <= `FALSE;
                enable_to_predictor <= `FALSE;
                rollback_flag <= `FALSE;
                is_jalr_commit_to_fetcher <= `FALSE;
            end
            if (io_rob_id_from_lsb != `ROB_ID_RESET && busy[io_rob_id_from_lsb-1]) begin
                is_io_inst[io_rob_id_from_lsb-1] <= `TRUE;
            end
        end else begin
        end
    end



endmodule