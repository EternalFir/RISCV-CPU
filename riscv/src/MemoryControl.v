`include "constants.sv"

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
    input wire read_wirte_flag_from_lsu, // 1 for read, 0 for write
    input wire[`ADDR_TYPE ] address_from_lsu,
    input wire[`DATA_TYPE ] data_from_lsu,
    // input wire start_from_lsu,
    output reg end_to_lsu,
    output reg[`DATA_TYPE ] data_to_lsu,

);

    reg[2:0] rw_block_ram;
    reg rw_end_ram;

    reg[`INST_CNT_TYPE ] inst_read_cnt;

    always @(*) begin
        if (reset_from_fetcher == `TRUE) begin
            inst_read_cnt <= `INST_CNT_NUM;
            inst_to_fetcher <= `INST_RESET;
            end_to_fetcher <= `TRUE;
        end
    end

    always @(posedge clk_in) begin
        if (rst_in == `TRUE) begin
            read_write_flag_to_ram <= `FALSE;
            address_to_ram <= `ADDR_RESET;
            data_to_ram <= `MEMPORT_RESET;
            inst_to_fetcher <= `INST_RESET;
            data_to_lsu <= `DATA_RESET;
            rw_block_ram <= 3'h7;
            rw_end_ram <= `TRUE;
            inst_read_cnt <= `INST_CNT_NUM;
            one_inst_finish_to_fetcher <= `FALSE;
        end
        else if (rdy_in) begin
            end_to_fetcher <= `TRUE ;
            end_to_lsu <= `TRUE ;
            address_to_ram <= `ADDR_RESET;
            data_to_ram <= `MEMPORT_RESET;
            if (enable_from_lsu == `TRUE) begin // 存在 icache，故 memory 带宽应该优先保证 lsu 使用
                if (rw_end_ram && rw_block_ram > 3'h5) begin // first time
                    rw_end_ram <= `FALSE;
                    rw_block_ram <= 0;
                    address_to_ram<=address_from_lsu;
                end
                if (read_wirte_flag_from_lsu == `READ_SIT) begin // for read
                    read_write_flag_to_ram <= `READ_SIT;
                    case (rw_block_ram)
                        2'h0: data_to_lsu[7:0] <= data_from_ram;
                        2'h1: data_to_lsu[15:8] <= data_from_ram;
                        2'h2: data_to_lsu[23:16] <= data_from_ram;
                        2'h3: data_to_lsu[31:24] <= data_from_ram;
                    endcase
                end
                else begin // for write
                    read_write_flag_to_ram <= `WRITE_SIT;
                    case (rw_block_ram)
                        2'h0: data_to_ram <= data_from_lsu[7:0];
                        2'h1: data_to_ram <= data_from_lsu[15:8];
                        2'h2: data_to_ram <= data_from_lsu[23:16];
                        2'h3: data_to_ram <= data_from_lsu[31:24];
                    endcase
                end
                if (rw_block_ram >= 3'h3) begin // 是否直接就够了，还是说要再延一个周期
                    rw_end_ram <= `TRUE;
                end
                rw_block_ram <= rw_block_ram+1;
                if (rw_end_ram) begin
                    end_to_lsu <= `TRUE;
                end
            end
            else if (enable_from_fetcher) begin
                read_write_flag_to_ram <= `READ_SIT;
                if (inst_read_cnt == `INST_CNT_NUM) begin
                    inst_read_cnt <= 0;
                    one_inst_finish_to_fetcher <= `FALSE;
                end
                if (inst_read_cnt == 0) begin
                    // rw_end_ram <= `FALSE;
                    end_to_fetcher <= `FALSE;
                end
                if (rw_block_ram == 0) begin
                    address_to_ram <= addrress_from_fetcher+inst_read_cnt;
                end
                if (rw_block_ram == 1) begin
                    one_inst_finish_to_fetcher <= `FALSE;
                end
                if (end_to_fetcher == `FALSE) begin
                    case (rw_block_ram)
                        2'h0: inst_to_fetcher[7:0] <= data_from_ram;
                        2'h1: inst_to_fetcher[15:8] <= data_from_ram;
                        2'h2: inst_to_fetcher[23:16] <= data_from_ram;
                        2'h3: inst_to_fetcher[31:24] <= data_from_ram;
                    endcase
                    rw_block_ram <= rw_block_ram+1;
                    if (rw_block_ram == 4) begin
                        rw_block_ram <= 0;
                        inst_read_cnt <= inst_read_cnt+1;
                        one_inst_finish_to_fetcher <= `TRUE;
                    end
                end
                if (inst_read_cnt == `INST_CNT_NUM) begin
                    end_to_fetcher <= `TRUE;


                end
            end
            else begin
                rw_block_ram <= 3'h0;
            end
        end
        else if (~rdy_in) begin
            // halt
        end
    end

endmodule
