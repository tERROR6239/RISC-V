\m4_TLV_version 1d: tl-x.org
\SV
   
   m4_include_lib(['https://raw.githubusercontent.com/tERROR6239/RISC-V/main/risc-v_defs.tlv'])
   m4_include_lib(['https://raw.githubusercontent.com/tERROR6239/RISC-V/main/risc-v_shell_lib.tlv'])

   //---------------------------------------------------------------------------------
   // /====================\
   // | Sum 1 to 9 Program |
   // \====================/
   //
   // Program to test RV32I
   // Add 1,2,3,...,9 (in that order).
   //
   // Regs:
   //  x12 (a2): 10
   //  x13 (a3): 1..10
   //  x14 (a4): Sum
   //m4_asm(ADDI, x14, x0, 0)             // Initialize sum register a4 with 0
   //m4_asm(ADDI, x12, x0, 1010)          // Store count of 10 in register a2.
   //m4_asm(ADDI, x13, x0, 1)             // Initialize loop count register a3 with 0
   // Loop:
   //m4_asm(ADD, x14, x13, x14)           // Incremental summation
   //m4_asm(ADDI, x13, x13, 1)            // Increment loop count by 1
   //m4_asm(BLT, x13, x12, 1111111111000) // If a3 is less than a2, branch to label named <loop>
   // Test result value in x14, and set x31 to reflect pass/fail.
   //m4_asm(ADDI, x30, x14, 111111010100) // Subtract expected value of 44 to set x30 to 1 if and only iff the result is 45 (1 + 2 + ... + 9).
   //m4_asm(BGE, x0, x0, 0) // Done. Jump to itself (infinite loop). (Up to 20-bit signed immediate plus implicit 0 bit (unlike JALR) provides byte address; last immediate bit should also be 0)
   //m4_asm(ADDI, x0, x0, 0101)
   //m4_asm_end()
   //m4_define(['M4_MAX_CYC'], 50)
                   
   //New Test Program
   m4_test_prog()    
   //---------------------------------------------------------------------------------

\SV
   m4_makerchip_module
   
\TLV
   
   $reset = *reset;
      
     
   //PC
   $pc[31:0] = >>1$next_pc;
   $next_pc[31:0] = $reset ? 0 :
                    $taken_br ? $br_targ_pc :
                    $ins_jal   ? $br_targ_pc :
                    $ins_jalr  ? $jalr_targ_pc :
                    $pc + 4;
   
   //IMem
   `READONLY_MEM($pc, $$instr[31:0])
   
   //DECODE 
   //Instruction Type
   $u_ins = $instr[6:2] ==? 5'b0x101;
   $s_ins = $instr[6:2] ==? 5'b0100x;
   $b_ins = $instr[6:2] ==? 5'b11000;
   $j_ins = $instr[6:2] ==? 5'b11011;
   $r_ins = $instr[6:2] == 5'b01011 || 
            $instr[6:2] == 5'b01100 || 
            $instr[6:2] == 5'b01110;
   $i_ins = $instr[6:2] ==? 5'b0000x || 
            $instr[6:2] ==? 5'b001x0 || 
            $instr[6:2] == 5'b11001;
                 
   //Data
   $rsrc2[4:0] = $instr[24:20];
   $rsrc1[4:0] = $instr[19:15];
   $funct3[2:0] = $instr[14:12];
   $rdata[4:0] = $instr[11:7];
   $opcode[6:0] = $instr[6:0];
   
   //Validation
   $rsrc2_val =  $r_ins || $s_ins || $b_ins;
   $rsrc1_val =  $r_ins || $i_ins || $s_ins || $b_ins;
   $funct3_val = $r_ins || $i_ins || $s_ins || $b_ins;
   $rdata_val =  $r_ins || $i_ins || $u_ins || $j_ins;
   $imm_val =    $i_ins || $s_ins || $b_ins || $u_ins || $j_ins;
   
   //Warnings Suppress
   `BOGUS_USE($funct3_val $imm_val)
   
   //Immediate
   $imm[31:0] = $i_ins ? { {21{$instr[31]}}, $instr[30:20] } :
                $s_ins ? { {21{$instr[31]}}, $instr[30:25], $instr[11:7]} :
                $b_ins ? { {20{$instr[31]}}, $instr[7], $instr[30:25], $instr[11:8], 1'b0} :
                $u_ins ? { $instr[31:12], 12'b0} :
                $j_ins ? { {12{$instr[31]}}, $instr[19:12], $instr[20], $instr[30:21], 1'b0} :
                           32'b0; // Default
   
   //Instructions              
   $dec_bits[10:0] = {$instr[30],$funct3,$opcode};
   $ins_beq =   $dec_bits ==? 11'bx_000_1100011;
   $ins_bne =   $dec_bits ==? 11'bx_001_1100011;
   $ins_blt =   $dec_bits ==? 11'bx_100_1100011;
   $ins_bge =   $dec_bits ==? 11'bx_101_1100011;
   $ins_bltu =  $dec_bits ==? 11'bx_110_1100011;
   $ins_bgeu =  $dec_bits ==? 11'bx_111_1100011;
   $ins_addi =  $dec_bits ==? 11'bx_000_0010011;
   $ins_add =   $dec_bits ==? 11'b0_000_0110011;
   $ins_lui =   $dec_bits ==? 11'bx_xxx_0110111;
   $ins_auipc = $dec_bits ==? 11'bx_xxx_0010111;
   $ins_jal =   $dec_bits ==? 11'bx_xxx_1101111;
   $ins_jalr =  $dec_bits ==? 11'bx_000_1100111;
   $ins_slti =  $dec_bits ==? 11'bx_010_0010011;
   $ins_sltiu = $dec_bits ==? 11'bx_011_0010011;
   $ins_xori =  $dec_bits ==? 11'bx_100_0010011;
   $ins_ori =   $dec_bits ==? 11'bx_110_0010011;
   $ins_andi =  $dec_bits ==? 11'bx_111_0010011;
   $ins_slli =  $dec_bits ==? 11'b0_001_0010011;
   $ins_srli =  $dec_bits ==? 11'b0_101_0010011;
   $ins_srai =  $dec_bits ==? 11'b1_101_0010011;
   $ins_sub =   $dec_bits ==? 11'b1_000_0110011;
   $ins_sll =   $dec_bits ==? 11'b0_001_0110011;
   $ins_slt =   $dec_bits ==? 11'b0_010_0110011;
   $ins_sltu =  $dec_bits ==? 11'b0_011_0110011;
   $ins_xor =   $dec_bits ==? 11'b0_100_0110011;
   $ins_srl =   $dec_bits ==? 11'b0_101_0110011;
   $ins_sra =   $dec_bits ==? 11'b1_101_0110011;
   $ins_or =    $dec_bits ==? 11'b0_110_0110011;
   $ins_and =   $dec_bits ==? 11'b0_111_0110011;
   $ins_load =  $dec_bits ==? 11'bx_xxx_0000011;
   
   //SLTU and SLTI Instuctions
   $sltu_rslt[31:0]  = {31'b0, $src1_value < $src2_value};
   $sltiu_rslt[31:0] = {31'b0, $src1_value < $imm};
   
   //SRA and SRAI
   //extend source1
   $sext_src1[63:0] = {{32{$src1_value[31]}}, $src1_value};
   //64-bit results
   $sra_rslt[63:0]  = $sext_src1 >> $src2_value[4:0];
   $srai_rslt[63:0] = $sext_src1 >> $imm[4:0];
   
   //Arithmetic Logic Unit
   $result[31:0] = $ins_addi  ? $src1_value + $imm :
                   $ins_add   ? $src1_value + $src2_value :
                   $ins_andi  ? $src1_value & $imm :
                   $ins_ori   ? $src1_value | $imm :
                   $ins_xori  ? $src1_value ^ $imm :
                   $ins_slli  ? $src1_value << $imm[5:0] :
                   $ins_srli  ? $src1_value >> $imm[5:0] :
                   $ins_and   ? $src1_value & $src2_value :
                   $ins_or    ? $src1_value | $src2_value :
                   $ins_xor   ? $src1_value ^ $src2_value :
                   $ins_sub   ? $src1_value - $src2_value :
                   $ins_sll   ? $src1_value << $src2_value[4:0] :
                   $ins_srl   ? $src1_value >> $src2_value[4:0] :
                   $ins_sltu  ? $sltu_rslt :
                   $ins_sltiu ? $sltiu_rslt :
                   $ins_lui   ? {$imm[31:12],12'b0} :
                   $ins_auipc ? $pc + $imm :
                   $ins_jal   ? $pc + 32'd4 :
                   $ins_jalr  ? $pc + 32'd4 :
                   $ins_slt   ? (($src1_value[31] == $src2_value[31]) ? $sltu_rslt : {31'b0, $src1_value[31]}) :
                   $ins_slti  ? (($src1_value[31] == $imm[31]) ? $sltiu_rslt : {31'b0, $src1_value[31]}) :
                   $ins_sra   ? $sra_rslt[31:0] :
                   $ins_srai  ? $srai_rslt[31:0] :
                   $ins_load  ? $src1_value + $imm :
                   $s_ins     ? $src1_value + $imm :
                   32'b0;
   
   //Register File Write
   $wr_data[31:0] = $ins_load ? $ld_data :
                    $r_ins || $i_ins || $u_ins || $j_ins ? $result[31:0]:   
                    32'b0;
   
   $wr_en = $rdata_val && ($rdata != 0) ? 1'b1:
          1'b0;
   
   //Branch
   $taken_br = $ins_beq ?  ($src1_value == $src2_value) :
               $ins_bne ?  ($src1_value != $src2_value) :
               $ins_blt ?  (($src1_value < $src2_value) ^ ($src1_value[31] != $src2_value[31])) :
               $ins_bge ?  (($src1_value >= $src2_value) ^ ($src1_value[31] != $src2_value[31])) :
               $ins_bltu ? ($src1_value < $src2_value) :
               $ins_bgeu ? ($src1_value >= $src2_value) :
               1'b0;
   
   //Compute Branch Adress
   $br_targ_pc[31:0] = $pc + $imm;
   
   //Compute JALR Adress
   $jalr_targ_pc[31:0] = $src1_value + $imm;   
   
   m4+tb()
   
   *failed = *cyc_cnt > M4_MAX_CYC;
   
   m4+rf(32, 32, $reset, $wr_en, $rdata[4:0], $wr_data[31:0], $rsrc1_val, $rsrc1[4:0], $src1_value, $rsrc2_val, $rsrc2[4:0], $src2_value)
   m4+dmem(32, 32, $reset, $result[4:0], $s_ins, $src2_value[31:0], $ins_load, $ld_data)
   m4+cpu_viz()
   
\SV
   endmodule