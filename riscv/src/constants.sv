
// constant for all
`define TRUE 1'b1
`define FALSE 1'b0

// constants for ram
`define ADDR_WIDTH 6
`define DATA_WIDTH 8
`define READ_SIT 1
`define WRITE_SIT 0
`define INST_CNT_TYPE 7:0
`define INST_CNT_NUM 8

// constants for fetcher
`define ICACHE_SIZE 512
`define ICACHE_TYPE 12:0
`define IQUEUE_SIZE_ 8 // rz 插件貌似不支持某些名称

// constant of types
`define INT_TYPE 31:0
`define MEMPORT_TYPE 7:0 // rz 插件貌似不支持某些名称
`define ADDR_TYPE 31:0
`define INST_TYPE 31:0
`define DATA_TYPE 31:0
`define INST_QUEUE_TYPE 2:0


// constant of reset
`define MEMPORT_RESET 8'h0
`define ADDR_RESET 32'h0
`define INST_RESET 32'h0
`define DATA_RESET 32'h0
`define PC_RESET 32'h0
`define INST_QUEUE_RESET 3'h0