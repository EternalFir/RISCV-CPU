// constant for all
`define TRUE 1'b1
`define FALSE 1'b0
`define FULL_PRESERVE 2

// constants of ram
`define ADDR_WIDTH 6
`define DATA_WIDTH 8
`define READ_SIT 1
`define WRITE_SIT 0
`define INST_CNT_TYPE 7:0
`define INST_CNT_NUM 8

// constants of fetcher
`define ICACHE_SIZE 512
`define ICACHE_TYPE 12:0
`define IQUEUE_SIZE_ 8 // rz 插件貌似不支持某些名称

// constants of types
`define INT_TYPE 31:0
`define MEMPORT_TYPE 7:0 // rz 插件貌似不支持某些名称
`define ADDR_TYPE 31:0
`define INST_TYPE 31:0
`define DATA_TYPE 31:0
`define INST_QUEUE_TYPE 2:0

// constants of register
`define REG_TYPE 4:0
`define REG_SIZE 32
`define REG_RESET 5'd0

// constants of reservation_station
`define RS_TYPE 4:0
`define RS_SIZE 16
`define RS_OUT_OF_RANGE 5'h10

// constants of load_store_buffer
`define LSB_TYPE 4:0
`define LSB_SIZE 16
`define LSB_OUT_OF_RANGE 5'h10

// constants of reorder_buffer
`define ROB_SIZE 16
`define ROB_TYPE 4:0
`define ROB_RESET 5'h0

// constants of reset
`define MEMPORT_RESET 8'h0
`define ADDR_RESET 32'h0
`define INST_RESET 32'h0
`define DATA_RESET 32'h0
`define PC_RESET 32'h0
`define INST_QUEUE_RESET 3'h0

// constants of predictor
`define PREDICTOR_SIZE 512

// constants of op_code_range
`define OPCODE_RANGE 6:0
`define FUNC3_RANGE 14:12
`define FUNC7_RANGE 31:25
`define RD_RANGE 11:7
`define RS1_RANGE 19:15
`define RS2_RANGE 24:20

// constants of opcode types
`define OPCODE_LUI 7'b0110111
`define OPCODE_AUIPC 7'b0010111
`define OPCODE_JAL 7'b1101111
`define OPCODE_JALR 7'b1100111
`define OPCODE_BRANCH 7'b1100011
`define OPCODE_LOAD 7'b0000011
`define OPCODE_STORE 7'b0100011
`define OPCODE_ARITHI 7'b0010011
`define OPCODE_ARITH 7'b0110011

// constants of op_enum
`define OP_ENUM_TYPE 5:0

`define OP_ENUM_RESET 6'd0

`define OP_ENUM_LUI 6'd1
`define OP_ENUM_AUIPC 6'd2

`define OP_ENUM_JAL 6'd3
`define OP_ENUM_JALR 6'd4

`define OP_ENUM_BEQ 6'd5
`define OP_ENUM_BNE 6'd6
`define OP_ENUM_BLT 6'd7
`define OP_ENUM_BGE 6'd8
`define OP_ENUM_BLTU 6'd9
`define OP_ENUM_BGEU 6'd10

`define OP_ENUM_LB 6'd11
`define OP_ENUM_LH 6'd12
`define OP_ENUM_LW 6'd13
`define OP_ENUM_LBU 6'd14
`define OP_ENUM_LHU 6'd15
`define OP_ENUM_SB 6'd16
`define OP_ENUM_SH 6'd17
`define OP_ENUM_SW 6'd18

`define OP_ENUM_ADD 6'd19
`define OP_ENUM_SUB 6'd20
`define OP_ENUM_SLL 6'd21
`define OP_ENUM_SLT 6'd22
`define OP_ENUM_SLTU 6'd23
`define OP_ENUM_XOR 6'd24
`define OP_ENUM_SRL 6'd25
`define OP_ENUM_SRA 6'd26
`define OP_ENUM_OR 6'd27
`define OP_ENUM_AND 6'd28

`define OP_ENUM_ADDI 6'd29
`define OP_ENUM_SLTI 6'd30
`define OP_ENUM_SLTIU 6'd31
`define OP_ENUM_XORI 6'd32
`define OP_ENUM_ORI 6'd33
`define OP_ENUM_ANDI 6'd34
`define OP_ENUM_SLLI 6'd35
`define OP_ENUM_SRLI 6'd36
`define OP_ENUM_SRAI 6'd37

// func3
`define FUNC3_JALR 3'b000

`define FUNC3_BEQ 3'b000
`define FUNC3_BNE 3'b001
`define FUNC3_BLT 3'b100
`define FUNC3_BGE 3'b101
`define FUNC3_BLTU 3'b110
`define FUNC3_BGEU 3'b111

`define FUNC3_LB 3'b000
`define FUNC3_LH 3'b001
`define FUNC3_LW 3'b010
`define FUNC3_LBU 3'b100
`define FUNC3_LHU 3'b101

`define FUNC3_SB 3'b000
`define FUNC3_SH 3'b001
`define FUNC3_SW 3'b010

`define FUNC3_ADDI 3'b000
`define FUNC3_SLTI 3'b010
`define FUNC3_SLTIU 3'b011
`define FUNC3_XORI 3'b100
`define FUNC3_ORI 3'b110
`define FUNC3_ANDI 3'b111
`define FUNC3_SLLI 3'b001
`define FUNC3_SRLI 3'b101
`define FUNC3_SRAI 3'b101

`define FUNC3_ADD 3'b000
`define FUNC3_SUB 3'b000
`define FUNC3_SLL 3'b001
`define FUNC3_SLT 3'b010
`define FUNC3_SLTU 3'b011
`define FUNC3_XOR 3'b100
`define FUNC3_SRL 3'b101
`define FUNC3_SRA 3'b101
`define FUNC3_OR 3'b110
`define FUNC3_AND 3'b111

// func7
`define FUNC7_RESET 7'b0000000
`define FUNC7_SPEC 7'b0100000