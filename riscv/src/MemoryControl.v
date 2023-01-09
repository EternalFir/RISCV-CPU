`include "constants.v"

module MemoryControl(
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,

    // connect with ram
    output reg read_write_flag_to_ram, // 1 for read, 0 for write
    output reg[`ADDR_TYPE ] address_to_ram,
    output reg[`MEMPORT_TYPE] data_to_ram,
    //TODO: 分四次读取？
    input wire[`MEMPORT_TYPE ] data_from_ram,

    // connect with fetcher
    input wire enable_from_fetcher,
    input wire[`ADDR_TYPE ] addrress_from_fetcher,
    input wire reset_from_fetcher,
    // input wire start_from_fetcher,
    output reg end_to_fetcher,
    output reg one_inst_finish_to_fetcher,
    output reg[`INST_TYPE ] inst_to_fetcher,

    //connect with lsu
    input wire enable_from_lsu,
    input wire read_wirte_flag_from_lsu, // 0 for read, 1 for write
    input wire[`ADDR_TYPE ] address_from_lsu,
    input wire[`DATA_TYPE ] data_from_lsu,
    // input wire start_from_lsu,
    output reg end_to_lsu,
    output reg[`DATA_TYPE ] data_to_lsu,

    // broadcast to fetcher and lsu
    output reg aviliable,

    // io_buffer_full_signal_from_outside
    input wire io_buffer_full
);

    reg[2:0] rw_block_ram;
    reg rw_end_ram;

    reg is_with_lsu;
    reg is_with_fetcher;
    reg one_inst_going_to_finish;

    reg is_inst_before;
    reg is_data_before;

    reg[`INST_CNT_TYPE ] inst_read_cnt;
    reg is_io_inst;

    // reg dbg_io_port_visited;


    // always @(*) begin
    //     if (reset_from_fetcher == `TRUE) begin
    //         inst_read_cnt <= `INST_CNT_RESET;
    //         inst_to_fetcher <= `INST_RESET;
    //         end_to_fetcher <= `FALSE;
    //         is_io_inst <= `FALSE;
    //
    //         dbg_io_port_visited <= `FALSE;
    //     end
    // end

    always @(posedge clk_in) begin
        if (rst_in == `TRUE) begin
            read_write_flag_to_ram <= `FALSE;
            address_to_ram <= `ADDR_RESET;
            data_to_ram <= `MEMPORT_RESET;
            inst_to_fetcher <= `INST_RESET;
            data_to_lsu <= `DATA_RESET;
            rw_block_ram <= 3'h7;
            rw_end_ram <= `TRUE;
            inst_read_cnt <= `INST_CNT_RESET;
            one_inst_finish_to_fetcher <= `FALSE;
            one_inst_going_to_finish <= `FALSE;
            end_to_fetcher <= `FALSE;
            aviliable <= `TRUE;
            is_with_lsu <= `FALSE;
            is_with_fetcher <= `FALSE;
            is_inst_before <= `FALSE;
            is_data_before <= `FALSE;
            is_io_inst <= `FALSE;


            // dbg_io_port_visited <= `FALSE;
        end
        else if (rdy_in) begin
            if (one_inst_going_to_finish) begin
                one_inst_finish_to_fetcher <= `TRUE;
                one_inst_going_to_finish <= `FALSE;
            end else begin
                one_inst_finish_to_fetcher <= `FALSE;
            end
            // end_to_fetcher <= `FALSE;
            // end_to_lsu <= `TRUE;
            address_to_ram <= `ADDR_RESET;
            data_to_ram <= `MEMPORT_RESET;

            // dbg_io_port_visited <= `FALSE;

            if (aviliable && enable_from_lsu) begin
                aviliable <= `FALSE;
                is_with_lsu <= `TRUE;
                rw_block_ram <= 0;
                end_to_lsu <= `FALSE;
                address_to_ram <= address_from_lsu;
                is_data_before <= `TRUE;
                is_inst_before <= `FALSE;
                read_write_flag_to_ram <= read_wirte_flag_from_lsu;


                if (address_from_lsu == `RAM_IO_PORT) begin
                    // dbg_io_port_visited <= `TRUE;
                    is_io_inst <= `TRUE;
                    data_to_ram <= data_from_lsu[7:0];
                end
            end
            if (is_with_lsu) begin
                if (is_io_inst && io_buffer_full) begin
                    rw_block_ram<=rw_block_ram;
                    address_to_ram<=address_to_ram;
                    data_to_ram<=data_to_ram;
                end else begin
                    if (read_wirte_flag_from_lsu == `READ_SIT) begin // for read
                        // read_write_flag_to_ram <= `READ_SIT;
                        case (rw_block_ram)
                            3'h1: data_to_lsu[7:0] <= data_from_ram;
                            3'h2: data_to_lsu[15:8] <= data_from_ram;
                            3'h3: data_to_lsu[23:16] <= data_from_ram;
                            3'h4: data_to_lsu[31:24] <= data_from_ram;
                        endcase
                        if (is_io_inst) begin
                            address_to_ram<=`ADDR_RESET ;
                        end else begin
                            address_to_ram <= address_to_ram+1;
                        end
                        rw_block_ram <= rw_block_ram+1;

                        if (rw_block_ram == 4) begin
                            end_to_lsu <= `TRUE;
                            // aviliable <= `TRUE;
                            is_with_lsu <= `FALSE;
                        end
                    end
                    else begin // for write
                        // read_write_flag_to_ram <= `WRITE_SIT;
                        if (is_io_inst) begin
                            // data_to_ram <= data_from_lsu[7:0];
                            // address_to_ram <= address_to_ram;
                            data_to_ram<=`DATA_RESET ;
                            address_to_ram<=`ADDR_RESET ;
                        end else begin
                            case (rw_block_ram)
                                3'h0: data_to_ram <= data_from_lsu[7:0];
                                3'h1: data_to_ram <= data_from_lsu[15:8];
                                3'h2: data_to_ram <= data_from_lsu[23:16];
                                3'h3: data_to_ram <= data_from_lsu[31:24];
                                3'h4: data_to_ram <= data_from_lsu[31:24];
                                // 3'h1: data_to_ram <= data_from_lsu[7:0];
                                // 3'h2: data_to_ram <= data_from_lsu[15:8];
                                // 3'h3: data_to_ram <= data_from_lsu[23:16];
                                // 3'h4: data_to_ram <= data_from_lsu[31:24];
                            endcase
                            if (rw_block_ram > 0 && rw_block_ram < 4) begin
                                address_to_ram <= address_to_ram+1;
                            end else begin
                                address_to_ram <= address_to_ram;
                            end
                        end
                        rw_block_ram <= rw_block_ram+1;
                        if (rw_block_ram == 4) begin
                            end_to_lsu <= `TRUE;
                            // aviliable <= `TRUE;
                            is_with_lsu <= `FALSE;
                            is_io_inst <= `FALSE;
                        end
                    end
                end

            end
            // if (rw_end_ram && rw_block_ram > 3'h5) begin // first time
            //     rw_end_ram <= `FALSE;
            //     rw_block_ram <= 0;
            //     address_to_ram <= address_from_lsu;
            // end else begin
            //     address_to_ram <= address_to_ram+1;
            // end
            // if (read_wirte_flag_from_lsu == `READ_SIT) begin // for read
            //     read_write_flag_to_ram <= `READ_SIT;
            //     case (rw_block_ram)
            //         2'h0: data_to_lsu[7:0] <= data_from_ram;
            //         2'h1: data_to_lsu[15:8] <= data_from_ram;
            //         2'h2: data_to_lsu[23:16] <= data_from_ram;
            //         2'h3: data_to_lsu[31:24] <= data_from_ram;
            //     endcase
            // end
            // else begin // for write
            //     read_write_flag_to_ram <= `WRITE_SIT;
            //     case (rw_block_ram)
            //         2'h0: data_to_ram <= data_from_lsu[7:0];
            //         2'h1: data_to_ram <= data_from_lsu[15:8];
            //         2'h2: data_to_ram <= data_from_lsu[23:16];
            //         2'h3: data_to_ram <= data_from_lsu[31:24];
            //     endcase
            // end
            // if (rw_block_ram >= 3'h3) begin // 是否直接就够了，还是说要再延一个周期
            //     rw_end_ram <= `TRUE;
            // end
            // rw_block_ram <= rw_block_ram+1;
            // if (rw_end_ram) begin
            //     end_to_lsu <= `TRUE;
            // end
            if (aviliable && enable_from_fetcher && !enable_from_lsu) begin // 优先满足lsu
                aviliable <= `FALSE;
                end_to_fetcher <= `FALSE;
                is_with_fetcher <= `TRUE;
                read_write_flag_to_ram <= `READ_SIT;
                address_to_ram <= addrress_from_fetcher;
                inst_read_cnt <= 0;
                rw_block_ram <= 0;
                is_inst_before <= `TRUE;
                is_data_before <= `FALSE;
            end
            if (is_with_fetcher) begin
                case (rw_block_ram)
                    3'h1: inst_to_fetcher[7:0] <= data_from_ram;
                    3'h2: inst_to_fetcher[15:8] <= data_from_ram;
                    3'h3: inst_to_fetcher[23:16] <= data_from_ram;
                    3'h0: inst_to_fetcher[31:24] <= data_from_ram;
                endcase
                rw_block_ram <= rw_block_ram+1;
                if (rw_block_ram == 3) begin
                    rw_block_ram <= 0;
                    inst_read_cnt <= inst_read_cnt+1;
                    address_to_ram <= addrress_from_fetcher+(inst_read_cnt+1)*4;
                    one_inst_going_to_finish <= `TRUE;
                end else begin
                    address_to_ram <= address_to_ram+1;
                    one_inst_going_to_finish <= `FALSE;
                end
                if (inst_read_cnt == `INST_CNT_NUM) begin
                    end_to_fetcher <= `TRUE;
                    // inst_read_cnt <= `INST_CNT_RESET;
                    // aviliable<=`TRUE ;
                    is_with_fetcher <= `FALSE;
                end
            end
            // reset
            if (!aviliable && is_inst_before && !enable_from_fetcher) begin
                aviliable <= `TRUE;
                end_to_fetcher <= `FALSE;
            end
            if (!aviliable && is_data_before && !enable_from_lsu) begin
                aviliable <= `TRUE;
                end_to_lsu <= `FALSE;
            end
            if (!is_with_lsu && !is_with_fetcher) begin
                rw_block_ram <= 3'h0;
            end
        end
        else if (~rdy_in) begin
            // halt
        end
    end

endmodule
