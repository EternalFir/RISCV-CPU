`include "constants.v"
module Fetcher(
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,

    // connect with MemoryControl
    input wire end_from_memcont,
    input wire one_inst_finish_from_momcont,
    input wire[`INST_TYPE ] inst_from_memcont,
    input wire aviliable_from_memcont,
    output reg enable_to_memcont,
    // output reg start_to_memcont,
    output reg[`ADDR_TYPE ] address_to_memcont,
    // output reg reset_to_memcont,

    // connect with Predictor
    // input wire end_from_predictor,
    input wire[`ADDR_TYPE ] imm_from_predictor,
    input wire jump_predict_flag_from_predictor,
    input wire is_jalr_inst_from_predictor,
    // input wire undo_flag_from_predictor,
    // output reg enable_to_predictor,
    output wire[`ADDR_TYPE ] pc_to_predictor,
    output wire[`INST_TYPE ] inst_to_predictor,

    // connect with Dispatcher
    // input wire enable_from_dispatcher,
    // output reg end_to_dispatcher,
    output reg idle_to_dispatcher,
    output reg[`INST_TYPE ] inst_to_dispatcher,
    output reg[`ADDR_TYPE ] inst_pos_to_dispatcher,
    output reg if_jump_flag_predicted_to_dispatcher,
    output reg[`ADDR_TYPE ] rollback_pos_to_dispatcher, // pc pos if do not jump

    // connect with reorder buffer
    input wire[`ADDR_TYPE ] targer_pc_pos_from_rob,
    input wire is_jalr_commit_from_rob,

    // info from cdb broadcast
    input wire rollback_flag_from_rob,
    input wire full_flag_in
);
    reg[`ADDR_TYPE ] pc_pos_now;
    // reg[`ADDR_TYPE ] pc_pos_next;
    reg icache_vailed[`ICACHE_SIZE -1:0];
    reg[`INST_TYPE ] icache_inst[`ICACHE_SIZE-1:0];
    reg[`ADDR_TYPE ] icache_pos[`ICACHE_SIZE-1:0];
    // reg[`ICACHE_TYPE ] icache_num;
    reg[`INST_CNT_TYPE ] icache_get_cnt;
    reg[`INST_TYPE ] inst_queue[`IQUEUE_SIZE_-1:0];
    reg[`ADDR_TYPE ] inst_pos_queue[`IQUEUE_SIZE_-1:0];
    reg inst_jump_predict_queue[`IQUEUE_SIZE_ -1:0];
    reg[`ADDR_TYPE ] inst_rollback_pos_queue[`IQUEUE_SIZE_ -1:0];
    reg[3:0] inst_queue_num;
    reg[3:0] head, tail;
    // reg[`INST_QUEUE_TYPE ] inst_read_num;
    reg end_inst_read;
    reg[`ADDR_TYPE ] offset;
    reg[`INST_TYPE ] inst_handle_now;
    reg busy_with_memcont;
    reg busy_with_dispatcher;
    reg single_inst_read_end_flag;
    reg[`ADDR_TYPE ] pc_load_start;
    reg[`INST_TYPE ] temp_inst;
    wire[`ADDR_TYPE ] temp_inst_pos = pc_load_start+icache_get_cnt*4;
    reg jalr_halt; // 遇上 jalr 指令则先暂停流水线
    wire insert_signal = inst_queue_num <= 3'h4 && !jalr_halt && hit;
    wire lunch_signal = !full_flag_in && (inst_queue_num != 0);

    integer i;

    wire need_inst_load = !(icache_vailed[pc_pos_now[10:2]] && icache_pos[pc_pos_now[10:2]] == pc_pos_now);
    wire hit = (icache_vailed[pc_pos_now[10:2]] && icache_pos[pc_pos_now[10:2]] == pc_pos_now);
    wire[`INST_TYPE ] target_inst_in_cache = (hit) ? icache_inst[pc_pos_now[10:2]]:`ADDR_RESET;
    // reg[`ADDR_TYPE ] inst_need_to_load_pos;

    assign pc_to_predictor = pc_pos_now;
    assign inst_to_predictor = target_inst_in_cache;


    reg dbg_inst_load;
    reg[3:0] dbg_run_time_test;
    reg dbg_access_test_1;
    reg[`ADDR_TYPE ] dbg_object_inst_pos = 32'h00001200;
    wire[`INST_TYPE ] dbg_object_inst_in_cache = (icache_vailed[dbg_object_inst_pos[10:2]]) ? icache_inst[dbg_object_inst_pos[10:2]]:`INST_RESET;
    wire[`ADDR_TYPE ] dbg_object_inst_pos_in_cache = (icache_vailed[dbg_object_inst_pos[10:2]]) ? icache_pos[dbg_object_inst_pos[10:2]]:`ADDR_RESET;
    reg[32:0] dbg_predict_cnt;
    reg[32:0] dbg_rollback_cnt;


    always @(posedge clk_in) begin
        if (rst_in == `TRUE) begin
            enable_to_memcont <= `FALSE;
            address_to_memcont <= `ADDR_RESET;
            // need_inst_load <= `FALSE;
            pc_load_start <= `ADDR_RESET;
            // icache_num <= 0;
            for (i = 0; i < `ICACHE_SIZE;i = i+1) begin
                icache_inst[i] <= `INST_RESET;
                icache_pos[i] <= `ADDR_RESET;
                icache_vailed[i] <= `FALSE;
            end
            icache_get_cnt <= 0;
            // enable_from_dispatcher <= `FALSE;
            inst_to_dispatcher <= `INST_RESET;
            pc_pos_now <= `ADDR_RESET;
            // pc_pos_next <= `ADDR_RESET;
            head <= 0;
            tail <= 0;
            inst_queue_num <= 4'h0;
            // inst_read_num <= `INST_QUEUE_RESET;
            end_inst_read <= `TRUE;
            for (i = 0; i < `IQUEUE_SIZE_;i = i+1) begin
                inst_queue[i] <= `INST_RESET;
                inst_pos_queue[i] <= `ADDR_RESET;
                inst_jump_predict_queue[i] <= `FALSE;
                inst_rollback_pos_queue[i] <= `ADDR_RESET;
            end
            busy_with_memcont <= `FALSE;
            busy_with_dispatcher <= `FALSE;
            // single_inst_read_flag <= single_inst_read_end_flag <= `TRUE;
            // reset_to_memcont <= `FALSE;
            idle_to_dispatcher <= `FALSE;
            // inst_need_to_load_pos <= `ADDR_RESET;
            jalr_halt <= `FALSE;


            dbg_inst_load <= `FALSE;
            dbg_run_time_test <= 0;
            dbg_access_test_1 <= `FALSE;

            dbg_predict_cnt <= `DATA_RESET;
            dbg_rollback_cnt <= `DATA_RESET;

        end else if (rdy_in == `TRUE) begin
            // get 4 insts a group
            // icache中的保持线性，是否跳转到iqueue中去考虑
            // rollback_flag 不应该影响icache的运行
            if (need_inst_load && aviliable_from_memcont && !busy_with_memcont) begin
                // address_to_memcont <= inst_need_to_load_pos;
                address_to_memcont <= pc_pos_now;
                busy_with_memcont <= `TRUE;
                pc_load_start <= pc_pos_now;
                enable_to_memcont <= `TRUE;
                icache_get_cnt <= 8'h0;
            end
            if (busy_with_memcont) begin
                if (!end_from_memcont) begin
                    if (one_inst_finish_from_momcont) begin
                        // 使用指令对应的实际地址值进行 hash ，以避免后读入的指令覆盖了前面的
                        icache_inst[temp_inst_pos[10:2]] <= inst_from_memcont;
                        icache_pos[temp_inst_pos[10:2]] <= pc_load_start+icache_get_cnt*4;
                        icache_vailed[temp_inst_pos[10:2]] <= `TRUE;
                        icache_get_cnt <= icache_get_cnt+1;
                        temp_inst <= inst_from_memcont;
                    end
                end else begin
                    icache_inst[temp_inst_pos[10:2]] <= inst_from_memcont;
                    icache_pos[temp_inst_pos[10:2]] <= pc_load_start+icache_get_cnt*4;
                    icache_vailed[temp_inst_pos[10:2]] <= `TRUE;
                    icache_get_cnt <= icache_get_cnt+1;
                    temp_inst <= inst_from_memcont;
                    enable_to_memcont <= `FALSE;
                    busy_with_memcont <= `FALSE;


                    dbg_run_time_test <= dbg_run_time_test+1;

                end
            end

            if (rollback_flag_from_rob) begin
                for (i = 0; i < `IQUEUE_SIZE_;i = i+1) begin
                    inst_queue[i] <= `INST_RESET;
                    inst_pos_queue[i] <= `ADDR_RESET;
                    inst_jump_predict_queue[i] <= `FALSE;
                    inst_rollback_pos_queue[i] <= `ADDR_RESET;
                end
                head <= 0;
                tail <= 0;
                inst_queue_num <= 4'h0;
                pc_pos_now <= targer_pc_pos_from_rob;
                jalr_halt <= `FALSE;
                idle_to_dispatcher <= `FALSE;

                dbg_rollback_cnt <= dbg_rollback_cnt+1;
            end
            else begin

                if (is_jalr_commit_from_rob) begin
                    jalr_halt <= `FALSE;
                end

                if (insert_signal && !lunch_signal) begin
                    inst_queue_num <= inst_queue_num+1;
                end
                if (!insert_signal && lunch_signal) begin
                    inst_queue_num <= inst_queue_num-1;
                end

                // into iqueue
                if (insert_signal) begin
                    inst_queue[tail] <= icache_inst[pc_pos_now[10:2]];
                    inst_pos_queue[tail] <= icache_pos[pc_pos_now[10:2]];
                    inst_jump_predict_queue[tail] <= jump_predict_flag_from_predictor;
                    inst_rollback_pos_queue[tail] <= pc_pos_now+4;
                    tail <= (tail == (`IQUEUE_SIZE_ -1)) ? 0:tail+1;
                    if (jump_predict_flag_from_predictor) begin
                        pc_pos_now <= pc_pos_now+imm_from_predictor;
                    end else begin
                        pc_pos_now <= pc_pos_now+4;
                    end
                    if (is_jalr_inst_from_predictor) begin
                        jalr_halt <= `TRUE;
                    end


                    if (target_inst_in_cache[`OPCODE_RANGE ] == `OPCODE_BRANCH)
                        dbg_predict_cnt <= dbg_predict_cnt+1;

                end

                // // into iqueue
                // if (inst_queue_num <= 3'h4 && ~jalr_halt) begin
                //     if (hit) begin // hit
                //         inst_queue[inst_queue_num] <= icache_inst[pc_pos_now[10:2]];
                //         inst_pos_queue[inst_queue_num] <= icache_pos[pc_pos_now[10:2]];
                //         inst_jump_predict_queue[inst_queue_num] <= jump_predict_flag_from_predictor;
                //         inst_rollback_pos_queue[inst_queue_num] <= pc_pos_now+4;
                //         inst_queue_num <= inst_queue_num+1;
                //         // need_inst_load <= `FALSE;
                //         // jump_predict
                //         if (jump_predict_flag_from_predictor) begin
                //             pc_pos_now <= pc_pos_now+imm_from_predictor;
                //             // if_jump_flag_predicted_to_dispatcher <= `TRUE;
                //             // rollback_pos_to_dispatcher <= pc_pos_now+32;
                //         end else begin
                //             // if_jump_flag_predicted_to_dispatcher <= `FALSE;
                //             pc_pos_now <= pc_pos_now+4;
                //         end
                //         if(is_jalr_inst_from_predictor)begin
                //             jalr_halt<=`TRUE ;
                //         end
                //     end else begin // miss
                //
                //     end
                // end

                // lunch
                if (lunch_signal) begin
                    idle_to_dispatcher <= `TRUE;
                    inst_to_dispatcher <= inst_queue[head];
                    inst_pos_to_dispatcher <= inst_pos_queue[head];
                    if_jump_flag_predicted_to_dispatcher <= inst_jump_predict_queue[head];
                    rollback_pos_to_dispatcher <= inst_rollback_pos_queue[head];
                    head <= (head == (`IQUEUE_SIZE_ -1)) ? 0:head+1;
                end else begin
                    idle_to_dispatcher <= `FALSE;
                    inst_to_dispatcher <= `INST_RESET;
                    inst_pos_to_dispatcher <= `ADDR_RESET;
                    if_jump_flag_predicted_to_dispatcher <= `FALSE;
                    rollback_pos_to_dispatcher <= `ADDR_RESET;
                end

                // // lunch
                // if (!full_flag_in && inst_queue_num != 0) begin
                //     idle_to_dispatcher <= `TRUE;
                //     inst_to_dispatcher <= inst_queue[0];
                //     inst_pos_to_dispatcher <= inst_pos_queue[0];
                //     if_jump_flag_predicted_to_dispatcher <= inst_jump_predict_queue[0];
                //     rollback_pos_to_dispatcher <= inst_rollback_pos_queue[0];
                //     inst_queue_num <= inst_queue_num-1;
                //     for (i = 0; i < `IQUEUE_SIZE_-1;i = i+1) begin
                //         inst_queue[i] <= inst_queue[i+1];
                //         inst_pos_queue[i] <= inst_pos_queue[i+1];
                //         inst_jump_predict_queue[i] <= inst_jump_predict_queue[i+1];
                //         inst_rollback_pos_queue[i] <= inst_rollback_pos_queue[i+1];
                //     end
                // end
                // else begin
                //     // end_to_dispatcher <= `FALSE;
                //     idle_to_dispatcher <= `FALSE;
                //     inst_to_dispatcher <= `INST_RESET;
                //     inst_pos_to_dispatcher <= `ADDR_RESET;
                //     if_jump_flag_predicted_to_dispatcher <= `FALSE;
                //     rollback_pos_to_dispatcher <= `ADDR_RESET;
                // end
            end

            // if(dbg_predict_cnt>=32'hbf613)begin
            //     $display("predict_cnt: %d , rollback_cnt: %d ", dbg_predict_cnt, dbg_rollback_cnt);
            // end

        end
        else begin

        end
    end


endmodule
