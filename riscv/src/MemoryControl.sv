`include "constants.sv"

module MemoryControl(
    input wire clk_in,
    input wire rst_in,
    input wire rdy_in,

    // connect with ram
    output reg read_write_flag_to_ram, // 0 for read, 1 for write
    output reg[`ADDR_TYPE ] address_to_ram,
    output reg[`MEMPORT_TYPE] data_to_ram,
    //TODO: 分四次读取？
    input wire[`MEMPORT_TYPE ] data_from_ram,

    // connect with fetcher
    input wire enable_from_fetcher,
    input wire[`ADDR_TYPE ] addrress_from_fetcher,
    // input wire start_from_fetcher,
    output reg end_to_fetcher,
    output reg[`INST_TYPE ] inst_to_fetcher,

    //connect with lsu
    input wire enable_from_lsu,
    input wire read_wirte_flag_from_lsu, // 0 for read, 1 for write
    input wire[`ADDR_TYPE ] address_from_lsu,
    input wire[`DATA_TYPE ] data_from_lsu,
    // input wire start_from_lsu,
    output reg end_to_lsu,
    output reg[`DATA_TYPE ] data_to_lsu,

);

    reg[2:0] rw_block_ram;
    reg rw_end_ram;

    always @(*) begin

    end

    always @(posedge clk_in) begin
        if (rst_in == `TRUE) begin
            read_write_flag_to_ram <= `FALSE;
            address_to_ram <= `ADDR_RESET;
            data_to_ram <= `MEMPORT_RESET;
            address_to_fetcher <= `ADDR_RESET;
            data_to_lsu <= `DATA_RESET;
            rw_block_ram <= 3'h7;
            rw_end_ram <= `TRUE;
        end
        else if (rdy_in) begin
            end_to_fetcher <= `FALSE;
            end_to_lsu <= `FALSE;
            address_to_ram <= `MEMPORT_RESET;
            data_to_ram <= `MEMPORT_RESET;
            if (enable_from_lsu == `TRUE) begin // 存在 icache，故 memory 带宽应该优先保证 lsu 使用
                if (rw_end_ram && rw_block_ram > 3'h5) begin // first time
                    rw_end_ram <= `FALSE;
                    rw_block_ram <= 0;
                end
                if (~read_wirte_flag_from_lsu) begin // for read
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
                read_write_flag_to_ram <= `WRITE_SIT;
                if (rw_end_ram && rw_block_ram > 3'h5) begin
                    rw_end_ram <= `FALSE;
                    rw_block_ram <= 0;
                end
                case (rw_block_ram)
                    2'h0: inst_to_fetcher[7:0] <= data_from_ram;
                    2'h1: inst_to_fetcher[15:8] <= data_from_ram;
                    2'h2: inst_to_fetcher[23:16] <= data_from_ram;
                    2'h3: inst_to_fetcher[31:24] <= data_from_ram;
                endcase
                if (rw_block_ram >= 3'h3) begin
                    rw_end_ram <= `TRUE;
                end
                rw_block_ram <= rw_block_ram+1;
                if (rw_end_ram) begin
                    end_to_fetcher <= `TRUE;
                end
            end
            else begin
                rw_block_ram <= 3'h7;
            end
        end
        else if (~rdy_in) begin
        end
    end

endmodule
