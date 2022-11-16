`include "constants.sv"
module Fetcher(
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,

    // connect with MemoryControl
    input wire end_from_memcont,
    input wire[`INST_TYPE ] inst_from_memcont,
    output reg enable_to_memcont,
    // output reg start_to_memcont,
    output reg[`ADDR_TYPE ] address_to_memcont,

    // connect with Predictor
    input wire end_from_predictor,
    input wire[`ADDR_TYPE ] address_from_predictor,
    input wire jump_predict_flag_from_predictor,
    input wire undo_flag_from_predictor,
    output reg enable_to_predictor,
    output reg[`ADDR_TYPE ] pc_to_predictor,

    // connect with Dispatcher
    input wire enable_from_dispatcher,
    output reg end_to_dispatcher,
    output reg[`INST_TYPE ] inst_to_dispatcher,

);
    reg[`ADDR_TYPE ] pc_pos_now;
    reg[`ADDR_TYPE ] pc_pos_next;
reg[`INST_TYPE ] inst_queue[`IQUEUE_SIZE ];
reg[`ADDR_TYPE ] inst_pos_queue[`IQUEUE_SIZE ];
    reg[3:0] inst_quque_num;
    reg[`INST_QUEUE_TYPE ] inst_read_num;
    reg end_inst_read;
    reg[`ADDR_TYPE ] offset;
    reg[`INST_TYPE ] inst_handle_now;
    reg busy_with_memcont;
    reg busy_with_dispatcher;
    reg single_inst_read_end_flag;

    always @(*) begin

    end

    always @(posedge clk_in) begin
        if (rst_in == `TRUE) begin
            enable_to_memcont <= `FALSE;
            address_to_memcont <= `ADDR_RESET;
            enable_from_dispatcher <= `FALSE;
            pc_to_predictor <= `PC_RESET;
            inst_to_dispatcher <= `INST_RESET;
            pc_pos_now <= `ADDR_RESET;
            pc_pos_next <= `ADDR_RESET;
            inst_quque_num <= 4'h0;
            inst_read_num <= `INST_QUEUE_RESET;
            end_inst_read <= `TRUE;
            for (i = 0; i < `IQUEUE_SIZE;i = i+1) begin
                inst_queue[i] <= `INST_RESET;
                inst_pos_queue[i] <= `ADDR_RESET;
            end
            busy_with_memcont <= `FALSE;
            busy_with_dispatcher <= `FALSE;
            single_inst_read_flag <= single_inst_read_end_flag <= `TRUE;
        end
        else if (rdy_in == `TRUE) begin

            // get 4 insts a group
            if (~busy_with_memcont && inst_quque_num <= 3'h4) begin
                end_inst_read <= `FALSE;
                inst_read_num <= `INST_QUEUE_RESET;
                busy_with_memcont <= `TRUE;
            end
            if (~end_inst_read && busy_with_memcont) begin
                if (single_inst_read_end_flag) begin
                    if (inst_quque_num > 1) begin
                        // get new pc address
                        if (((inst_queue[inst_quque_num-1] << 25)>> 30) == 32'h3) begin // is branch inst
                            inst_handle_now <= inst_queue[inst_quque_num-1];
                            offset <= `ADDR_RESET;
                            case ((inst_handle_now << 28)>> 28)
                                32'h3: begin
                                    offset <= (((inst_handle_now >> 8) << 28)>> 27)+(((inst_handle_now << 1)>> 26) << 5)+(((inst_handle_now << 24)>> 31) << 11)+((inst_handle_now >> 31) << 12);
                                    if (offset >= (32'h1 << 12)) begin
                                        offset <= offset+((32'hffffffff >> 13) << 13);
                                    end
                                end
                                32'h7: begin
                                    offset <= 32'h32; //JALR 默认不跳转
                                end
                                32'h15: begin
                                    offset <= (((inst_handle_now << 1)>> 22) << 1)+(((inst_handle_now << 11)>> 31) << 11)+(((inst_handle_now << 12)>> 24) << 12)+((inst_handle_now >> 31) << 20);
                                    if (offset >= (32'h1 << 20)) begin
                                        offset <= offset+((32'hffffffff >> 21) << 21);
                                    end
                                end
                            endcase
                            enable_to_predictor <= `TRUE;
                            pc_to_predictor <= inst_pos_queue[inst_quque_num-1];
                            if (jump_predict_flag_from_predictor) begin
                                pc_pos_now <= pc_pos_next-32+offset;

                            end
                            else begin
                                pc_pos_now <= pc_pos_next;
                            end
                        end
                        else begin
                            pc_pos_now <= pc_pos_next;
                        end
                    end
                    else begin
                        pc_pos_now <= pc_pos_next;
                    end
                    single_inst_read_end_flag <= `FALSE;
                    enable_to_memcont <= `TRUE;
                    address_to_memcont <= pc_pos_now;
                    pc_pos_next <= pc_pos_next+32;
                end
                else begin
                    if (~end_from_memcont) begin
                        // reading
                    end
                    else begin
                        // finished
                        single_inst_read_end_flag <= `TRUE;
                        enable_to_memcont <= `FALSE;
                        inst_read_num <= inst_read_num+1;
                    end
                end

            end
            if (inst_read_num >= 3'h4) begin
                inst_read_num <= 3'h0;
                end_inst_read <= `TRUE;
                busy_with_memcont <= `FALSE;
            end

            // sent inst to dispatcher
            if (enable_from_dispatcher) begin
                if (~busy_with_dispatcher) begin
                    busy_with_dispatcher <= `TRUE;
                    inst_to_dispatcher <= inst_queue[0];
                    for (i = 0; i < inst_quque_num-2;i = i+1) begin
                        inst_queue[i] <= inst_queue[i+1];
                        inst_pos_queue[i] <= inst_pos_queue[i+1];
                    end
                    inst_quque_num <= inst_quque_num-1;
                    end_to_dispatcher<=`TRUE;
                end
                else begin
                    busy_with_dispatcher<=`FALSE ;
                end
            end
            else begin
                end_to_dispatcher<=`FALSE ;
            end

            // check message from predictor


        end
        else begin

        end
    end



endmodule
