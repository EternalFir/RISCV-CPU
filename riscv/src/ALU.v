`include "constants.v"
// 真的不用超前进位加法器吗

module ALU(
    input wire[`OP_ENUM_TYPE ] op_enum,
    input wire[`DATA_TYPE ] V1,
    input wire[`DATA_TYPE ] V2,
    input wire[`DATA_TYPE ] imm,
    input wire[`ADDR_TYPE ] inst_pos,

    output reg busy,
    output reg jump_flag,
    output reg[`DATA_TYPE ] result,
    output reg[`ADDR_TYPE ] target_pos

);

    always @(*) begin
        busy = (op_enum != `OP_ENUM_RESET);
        result = `DATA_RESET;
        jump_flag = `FALSE;
        target_pos = `ADDR_RESET;
        case (op_enum)
            `OP_ENUM_LUI : begin
            result = imm;
        end
        `OP_ENUM_AUIPC: begin
            result = inst_pos+imm;
        end
        `OP_ENUM_JAL: begin
            target_pos = inst_pos+imm;
            result = inst_pos+4;
            jump_flag = `TRUE;
        end
        `OP_ENUM_JALR: begin
            target_pos = V1+imm;
            result = inst_pos+4;
            jump_flag = `TRUE;
        end
        `OP_ENUM_BEQ: begin
            target_pos = inst_pos+imm;
            jump_flag = (V1 == V2);
        end
        `OP_ENUM_BNE: begin
            target_pos = inst_pos+imm;
            jump_flag = (V1 != V2);
        end
        `OP_ENUM_BLT: begin
            target_pos = inst_pos+imm;
            jump_flag = ($signed(V1) < $signed(V2));
        end
        `OP_ENUM_BGE: begin
            target_pos = inst_pos+imm;
            jump_flag = ($signed(V1) >= $signed(V2));
        end
        `OP_ENUM_BLTU: begin
            target_pos = inst_pos+imm;
            jump_flag = (V1 < V2);
        end
        `OP_ENUM_BGEU: begin
            target_pos = inst_pos+imm;
            jump_flag = (V1 >= V2);
        end
        `OP_ENUM_ADD: begin
            result = V1+V2;
        end
        `OP_ENUM_SUB: begin
            result = V1-V2;
        end
        `OP_ENUM_SLL: begin
            result = (V1 << V2);
        end
        `OP_ENUM_SLT: begin
            result = ($signed(V1) < $signed(V2));
        end
        `OP_ENUM_SLTU: begin
            result = (V1 < V2);
        end
        `OP_ENUM_XOR: begin
            result = V1 ^ V2;
        end
        `OP_ENUM_SRL: begin
            result = (V1 >> V2);
        end
        `OP_ENUM_SRA: begin
            result = (V1 >>> V2);
        end
        `OP_ENUM_OR: begin
            result = (V1 | V2);
        end
        `OP_ENUM_AND: begin
            result = (V1 & V2);
        end
        `OP_ENUM_ADDI: begin
            result = V1+imm;
        end
        `OP_ENUM_SLLI: begin
            result = (V1 << imm);
        end
        `OP_ENUM_SLTI: begin
            result = ($signed(V1) < $signed(imm));
        end
        `OP_ENUM_SLTIU: begin
            result = (V1 < imm);
        end
        `OP_ENUM_XORI: begin
            result = V1 ^ imm;
        end
        `OP_ENUM_SRLI: begin
            result = (V1 >> imm);
        end
        `OP_ENUM_SRAI: begin
            result = (V1 >>> imm);
        end
        `OP_ENUM_ORI: begin
            result = (V1 | imm);
        end
        `OP_ENUM_ANDI: begin
            result = (V1 & imm);
        end
        endcase

        if (op_enum >= `OP_ENUM_BEQ && op_enum <= `OP_ENUM_BGEU) begin // for debug purpose
            result = jump_flag;
        end
    end

endmodule