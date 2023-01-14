`include "constants.v"

module LoadStoreBuffer(
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,

    // connect with dispatcher
    input wire enable_from_dispatcher,
    input wire[`OP_ENUM_TYPE ] op_enum_from_dispatcher,
    input wire[`DATA_TYPE ] V1_from_dispatcher,
    input wire[`DATA_TYPE ] V2_from_dispatcher,
    input wire[`DATA_TYPE ] imm_from_dispatcher,
    input wire[`ROB_ID_TYPE ] Q1_from_dispatcher,
    input wire[`ROB_ID_TYPE ] Q2_from_dispatcher,
    input wire[`ADDR_TYPE ] inst_pos_from_dispatcher,
    input wire[`ROB_ID_TYPE ] rob_id_from_dispatcher,
    output wire full_flag_to_dispatcher,

    // connect with lsu
    input wire busy_from_lsu,
    input wire end_from_lsu,
    input wire[`DATA_TYPE ] data_from_lsu,
    output reg enable_to_lsu,
    output reg read_write_flag_to_lsu,
    output reg[`OP_ENUM_TYPE ] op_enum_to_lsu,
    output reg[`ADDR_TYPE ] object_address_to_lsu,
    output reg[`DATA_TYPE ] data_to_lsu,

    // info from cdb broadcast
    input wire enable_from_alu,
    input wire[`ROB_ID_TYPE ] rob_id_from_rs,
    input wire[`DATA_TYPE ] result_from_alu,
    input wire enable_from_lsu,
    input wire[`ROB_ID_TYPE ] rob_id_from_lsb,
    input wire[`DATA_TYPE ] result_from_lsu,
    output reg[`ROB_ID_TYPE ] rob_id_to_cdb,

    // connect with rob
    input wire commit_flag_from_rob,
    input wire[`ROB_ID_TYPE ] rob_id_from_rob,
    input wire[`ROB_ID_TYPE ] head_io_rob_id_from_rob,
    output wire[`ROB_ID_TYPE ] io_rob_id_to_rob,
    input wire roll_back_flag_from_rob
);

    reg busy[`LSB_SIZE -1:0];
    reg[`OP_ENUM_TYPE ] op_enum[`LSB_SIZE -1:0];
    reg[`DATA_TYPE ] V1[`LSB_SIZE -1:0];
    reg[`DATA_TYPE ] V2[`LSB_SIZE -1:0];
    reg[`DATA_TYPE ] imm[`LSB_SIZE -1:0];
    reg[`ROB_ID_TYPE ] Q1[`LSB_SIZE -1:0];
    reg[`ROB_ID_TYPE ] Q2[`LSB_SIZE -1:0];
    reg[`ROB_ID_TYPE ] rob_id[`LSB_SIZE -1:0];
    reg committed[`LSB_SIZE -1:0];

    reg[`LSB_TYPE ] head, tail, commit_store_tail;
    reg[`ROB_TYPE ] element_num;
    wire full = element_num >= (`LSB_SIZE -`FULL_PRESERVE);
    wire insert_signal = enable_from_dispatcher;
    wire issue_signal = !react_halt && busy[head] && Q1[head] == `ROB_ID_RESET && Q2[head] == `ROB_ID_RESET && !busy_from_lsu && (((V1[head]+imm[head] != `RAM_IO_PORT || head_io_rob_id_from_rob == rob_id[head]) && op_enum[head] <= `OP_ENUM_LHU) || (op_enum[head] >= `OP_ENUM_SB && committed[head]));

    wire[`ROB_ID_TYPE ] Q1_insert = (enable_from_alu && Q1_from_dispatcher == rob_id_from_rs) ? `ROB_ID_RESET :((enable_from_lsu && Q1_from_dispatcher == rob_id_from_lsb) ?`ROB_ID_RESET :Q1_from_dispatcher);
    wire[`ROB_ID_TYPE ] Q2_insert = (enable_from_alu && Q2_from_dispatcher == rob_id_from_rs) ? `ROB_ID_RESET :((enable_from_lsu && Q2_from_dispatcher == rob_id_from_lsb) ?`ROB_ID_RESET :Q2_from_dispatcher);
    wire[`DATA_TYPE ] V1_insert = (enable_from_alu && Q1_from_dispatcher == rob_id_from_rs) ? result_from_alu:((enable_from_lsu && Q1_from_dispatcher == rob_id_from_lsb) ? result_from_lsu:V1_from_dispatcher);
    wire[`DATA_TYPE ] V2_insert = (enable_from_alu && Q2_from_dispatcher == rob_id_from_rs) ? result_from_alu:((enable_from_lsu && Q2_from_dispatcher == rob_id_from_lsb) ? result_from_lsu:V2_from_dispatcher);

    assign full_flag_to_dispatcher = full;
    assign io_rob_id_to_rob = ((V1[head]+imm[head]) == `RAM_IO_PORT) ? rob_id[head]:`ROB_ID_RESET;

    integer i;

    reg react_halt; // 避免一次向lsu连续发送两条指令

    reg dbg_inserted;
    reg dbg_executed;
    wire dbg_busy_head = busy[head];
    wire[`OP_ENUM_TYPE ] dbg_op_enum_head = op_enum[head];
    wire[`ROB_ID_TYPE ] dbg_Q1_head = Q1[head];
    wire[`ROB_ID_TYPE ] dbg_Q2_head = Q2[head];
    wire[`ROB_ID_TYPE ] dbg_rob_id_head = rob_id[head];
    wire[`ADDR_TYPE ] dbg_head_addr = V1[head]+imm[head];
    wire[`ROB_ID_TYPE ] dbg_commit_tail_rob_id = rob_id[commit_store_tail];


    always @(posedge clk_in) begin
        if (rst_in || (roll_back_flag_from_rob && commit_store_tail == `LSB_OUT_OF_RANGE_)) begin
            element_num <= `ROB_RESET;
            head <= `LSB_RESET_;
            tail <= `LSB_RESET_;
            commit_store_tail <= `LSB_OUT_OF_RANGE_;
            enable_to_lsu <= `FALSE;
            for (i = 0; i < `LSB_SIZE; i = i+1) begin
                busy[i] <= `FALSE;
                op_enum[i] <= `OP_ENUM_RESET;
                V1[i] <= `DATA_RESET;
                V2[i] <= `DATA_RESET;
                imm[i] <= `DATA_RESET;
                Q1[i] <= `ROB_ID_RESET;
                Q2[i] <= `ROB_ID_RESET;
                rob_id[i] <= `ROB_ID_RESET;
                committed[i] <= `FALSE;
            end
            react_halt <= `FALSE;

            dbg_inserted <= `FALSE;
            dbg_executed <= `FALSE;

        end
        else if (~rdy_in) begin
        end
        else begin
            if (end_from_lsu) begin
                react_halt <= `FALSE;
            end

            if (roll_back_flag_from_rob) begin // roll back to commit pos
                tail <= (commit_store_tail == `LSB_SIZE-1) ? 0:commit_store_tail+1;
                if (commit_store_tail >= head) begin
                    element_num <= commit_store_tail-head+1;
                end else begin
                    element_num <= `LSB_SIZE -head+commit_store_tail+1;
                end
                for (i = 0; i < `LSB_SIZE;i = i+1) begin
                    if (committed[i] == `FALSE || (`OP_ENUM_LB <= op_enum[i] && op_enum[i] <= `OP_ENUM_LHU)) begin
                        busy[i] <= `FALSE;
                    end
                end
            end
            else begin
                if (insert_signal && !issue_signal) begin
                    element_num <= element_num+1;
                end else if (issue_signal && !insert_signal) begin
                    element_num <= element_num-1;
                end
                // execute
                if (!busy_from_lsu && busy[head] && Q1[head] == `ROB_ID_RESET && Q2[head] == `ROB_ID_RESET && !react_halt) begin // 可直接用issue_signal替换
                    if (op_enum[head] >= `OP_ENUM_LB && op_enum[head] <= `OP_ENUM_LHU) begin // load
                        if (V1[head]+imm[head] != `RAM_IO_PORT || head_io_rob_id_from_rob == rob_id[head]) begin
                            enable_to_lsu <= `TRUE;
                            read_write_flag_to_lsu <= `READ_SIT;
                            op_enum_to_lsu <= op_enum[head];
                            object_address_to_lsu <= V1[head]+imm[head];
                            rob_id_to_cdb <= rob_id[head];
                            busy[head] <= `FALSE;
                            rob_id[head] <= `ROB_ID_RESET;
                            committed[head] <= `FALSE;
                            head <= (head == `LSB_SIZE-1) ? 0:head+1;
                            react_halt <= `TRUE;

                            dbg_executed <= `TRUE;
                        end
                    end else if (op_enum[head] >= `OP_ENUM_SB && op_enum[head] <= `OP_ENUM_SW && committed[head]) begin // store
                        enable_to_lsu <= `TRUE;
                        read_write_flag_to_lsu <= `WRITE_SIT;
                        op_enum_to_lsu <= op_enum[head];
                        object_address_to_lsu <= V1[head]+imm[head];
                        data_to_lsu <= V2[head];
                        rob_id_to_cdb <= rob_id[head];
                        busy[head] <= `FALSE;
                        rob_id[head] <= `ROB_ID_RESET;
                        committed[head] <= `FALSE;
                        head <= (head == `LSB_SIZE-1) ? 0:head+1;
                        if (commit_store_tail == head) begin
                            commit_store_tail <= `LSB_OUT_OF_RANGE_;
                        end
                        react_halt <= `TRUE;

                        dbg_executed <= `TRUE;
                    end else begin
                        enable_to_lsu <= `FALSE;


                        dbg_executed <= `FALSE;
                    end
                end
                else begin
                    enable_to_lsu <= `FALSE;


                    dbg_executed <= `FALSE;
                end
                // react to store inst commit
                if (commit_flag_from_rob) begin
                    for (i = 0; i < `LSB_SIZE;i = i+1) begin
                        if (busy[i] && rob_id[i] == rob_id_from_rob && !committed[i]) begin
                            committed[i] <= `TRUE;
                            if (op_enum[i] >= `OP_ENUM_SB) begin
                                commit_store_tail <= i;
                            end
                        end
                    end
                end

                // update for new result
                if (enable_from_alu) begin
                    for (i = 0; i < `LSB_SIZE;i = i+1) begin
                        if (Q1[i] == rob_id_from_rs) begin
                            V1[i] <= result_from_alu;
                            Q1[i] <= `ROB_ID_RESET;
                        end
                        if (Q2[i] == rob_id_from_rs) begin
                            V2[i] <= result_from_alu;
                            Q2[i] <= `ROB_ID_RESET;
                        end
                    end
                end
                if (enable_from_lsu) begin
                    for (i = 0; i < `LSB_SIZE;i = i+1) begin
                        if (Q1[i] == rob_id_from_lsb) begin
                            V1[i] <= result_from_lsu;
                            Q1[i] <= `ROB_ID_RESET;
                        end
                        if (Q2[i] == rob_id_from_lsb) begin
                            V2[i] <= result_from_lsu;
                            Q2[i] <= `ROB_ID_RESET;
                        end
                    end
                end
                // insert new inst
                if (enable_from_dispatcher) begin
                    busy[tail] <= `TRUE;
                    op_enum[tail] <= op_enum_from_dispatcher;
                    V1[tail] <= V1_insert;
                    V2[tail] <= V2_insert;
                    imm[tail] <= imm_from_dispatcher;
                    Q1[tail] <= Q1_insert;
                    Q2[tail] <= Q2_insert;
                    rob_id[tail] <= rob_id_from_dispatcher;
                    committed[tail] <= `FALSE;
                    tail <= (tail == `LSB_SIZE-1) ? 0:tail+1;


                    dbg_inserted <= `TRUE;
                end
                else begin
                    dbg_inserted <= `FALSE;
                end
            end
        end

    end



endmodule