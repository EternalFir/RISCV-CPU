`include "constants.v"

module Decode(
    input wire[`INST_TYPE ] inst_in,

    output reg[`OP_ENUM_TYPE ] op_enum,
    output reg[`REG_TYPE ] rd,
    output reg[`REG_TYPE ] rs1,
    output reg[`REG_TYPE ] rs2,
    output reg[`DATA_TYPE ] imm,
    output reg is_jump,
    output reg is_load,
    output reg is_store
);

    always @(*) begin
        op_enum = `OP_ENUM_RESET;
        rd = inst_in[`RD_RANGE ];
        rs1 = inst_in[`RS1_RANGE ];
        rs2 = inst_in[`RS2_RANGE ];
        imm = `DATA_RESET;
        is_jump = `FALSE;
        is_load = `FALSE;
        is_store = `FALSE;

        case (inst_in[`OPCODE_RANGE])
            `OPCODE_LUI, `OPCODE_AUIPC: begin // U-Type
            imm = {inst_in[31:12], 12'b0};
            if (inst_in[`OPCODE_RANGE] == `OPCODE_LUI)
                op_enum = `OP_ENUM_LUI;
            else
                op_enum = `OP_ENUM_AUIPC;
        end

        `OPCODE_JAL: begin // J-Type
            imm = {{12{inst_in[31]}}, inst_in[19:12], inst_in[20], inst_in[30:21], 1'b0};
            op_enum = `OP_ENUM_JAL;
            is_jump = `TRUE;
        end

        `OPCODE_BRANCH: begin // B-Type
            rd = `REG_RESET; // no rd
            imm = {{20{inst_in[31]}}, inst_in[7:7], inst_in[30:25], inst_in[11:8], 1'b0};
            is_jump = `TRUE;
            case (inst_in[`FUNC3_RANGE])
                `FUNC3_BEQ: op_enum = `OP_ENUM_BEQ;
                `FUNC3_BNE: op_enum = `OP_ENUM_BNE;
                `FUNC3_BLT: op_enum = `OP_ENUM_BLT;
                `FUNC3_BGE: op_enum = `OP_ENUM_BGE;
                `FUNC3_BLTU: op_enum = `OP_ENUM_BLTU;
                `FUNC3_BGEU: op_enum = `OP_ENUM_BGEU;
            endcase
        end

        `OPCODE_JALR, `OPCODE_LOAD, `OPCODE_ARITHI: begin // L-type&I-Type
            imm = {{21{inst_in[31]}}, inst_in[30:20]};
            case (inst_in[`OPCODE_RANGE])
                `OPCODE_JALR: begin
                op_enum = `OP_ENUM_JALR;
                is_jump = `TRUE;
                // jalr_cnt = jalr_cnt + 1;
                // if (jalr_cnt % 1000 == 0) $display("jalr: ", jalr_cnt);
            end
            `OPCODE_LOAD: begin
                case (inst_in[`FUNC3_RANGE])
                    `FUNC3_LB: op_enum = `OP_ENUM_LB;
                    `FUNC3_LH: op_enum = `OP_ENUM_LH;
                    `FUNC3_LW: op_enum = `OP_ENUM_LW;
                    `FUNC3_LBU: op_enum = `OP_ENUM_LBU;
                    `FUNC3_LHU: op_enum = `OP_ENUM_LHU;
                endcase
            end
            `OPCODE_ARITHI: begin
                if ((inst_in[`FUNC3_RANGE] == `FUNC3_SRAI) && (inst_in[`FUNC7_RANGE] == `FUNC7_SPEC)) begin
                    op_enum = `OP_ENUM_SRAI;
                end
                else begin
                    case (inst_in[`FUNC3_RANGE])
                        `FUNC3_ADDI: op_enum = `OP_ENUM_ADDI;
                        `FUNC3_SLTI: op_enum = `OP_ENUM_SLTI;
                        `FUNC3_SLTIU: op_enum = `OP_ENUM_SLTIU;
                        `FUNC3_XORI: op_enum = `OP_ENUM_XORI;
                        `FUNC3_ORI: op_enum = `OP_ENUM_ORI;
                        `FUNC3_ANDI: op_enum = `OP_ENUM_ANDI;
                        `FUNC3_SLLI: op_enum = `OP_ENUM_SLLI;
                        `FUNC3_SRLI: op_enum = `OP_ENUM_SRLI;
                    endcase
                end
                // shamt
                if (op_enum == `OP_ENUM_SLLI || op_enum == `OP_ENUM_SRLI || op_enum == `OP_ENUM_SRAI) begin
                    imm = imm[4:0];
                end
            end
            endcase
        end

        `OPCODE_STORE: begin // S-Type
            rd = `REG_RESET; // no rd
            imm = {{21{inst_in[31]}}, inst_in[30:25], inst_in[`RD_RANGE]};
            is_store = `TRUE;
            case (inst_in[`FUNC3_RANGE])
                `FUNC3_SB: op_enum = `OP_ENUM_SB;
                `FUNC3_SH: op_enum = `OP_ENUM_SH;
                `FUNC3_SW: op_enum = `OP_ENUM_SW;
            endcase
        end

        `OPCODE_ARITH: begin // R-Type
            if (inst_in[`FUNC3_RANGE] == `FUNC3_SUB && inst_in[`FUNC7_RANGE] == `FUNC7_SPEC) begin
                op_enum = `OP_ENUM_SUB;
            end

            else if (inst_in[`FUNC3_RANGE] == `FUNC3_SRAI && inst_in[`FUNC7_RANGE] == `FUNC7_SPEC) begin
                op_enum = `OP_ENUM_SRA;
            end
            else begin
                case (inst_in[`FUNC3_RANGE])
                    `FUNC3_ADD: op_enum = `OP_ENUM_ADD;
                    `FUNC3_SLT: op_enum = `OP_ENUM_SLT;
                    `FUNC3_SLTU: op_enum = `OP_ENUM_SLTU;
                    `FUNC3_XOR: op_enum = `OP_ENUM_XOR;
                    `FUNC3_OR: op_enum = `OP_ENUM_OR;
                    `FUNC3_AND: op_enum = `OP_ENUM_AND;
                    `FUNC3_SLL: op_enum = `OP_ENUM_SLL;
                    `FUNC3_SRL: op_enum = `OP_ENUM_SRL;
                endcase
            end
        end

            default begin
                op_enum = `OP_ENUM_RESET;
                imm = `DATA_RESET;
            end
        endcase
    end


endmodule