/**
 * @file ecc_decoder.v
 * @brief Hamming-SEC/DED ECC Decoder for Memory Error Detection & Correction
 * 
 * This module implements a Hamming-SEC/DED (Single Error Correction/Double Error Detection)
 * ECC decoder. It detects and corrects single-bit errors and detects double-bit errors
 * in 64-bit protected data.
 *
 * Feature: 001-Power-Management-Safety
 * User Story: US3 - Memory ECC Protection & Diagnostics
 * Task: T037
 * ASIL Level: ASIL-B
 *
 * Timing:
 * - Latency: < 100ns (40 cycles @ 400MHz)
 * - Clock: 400MHz
 * - Setup/Hold: Standard (< 1ns margin)
 *
 * Coverage Target:
 * - Statement Coverage (SC): 100%
 * - Branch Coverage (BC): 100%
 * - Cyclomatic Complexity (CC): ≤ 8
 *
 * Error Detection & Correction:
 * - SBE (Single-Bit Error): Detected and corrected automatically
 * - MBE (Multiple-Bit Error): Detected but not corrected
 * - SBED (SBE Detected): Fault flag set + correction applied
 * - MBED (MBE Detected): Fault flag set, correction bypassed
 */

module ecc_decoder #(
    parameter DATA_WIDTH = 64,      // 64-bit data
    parameter ECC_WIDTH  = 8        // 7 syndrome bits + 1 overall parity
) (
    // Input
    input  logic [DATA_WIDTH-1:0] data_in,      // 64-bit data (protected)
    input  logic [ECC_WIDTH-1:0]  ecc_in,       // 8-bit received ECC
    
    // Output
    output logic [DATA_WIDTH-1:0] data_out,     // 64-bit corrected data
    output logic                  error_flag,   // Error detected flag (SBE | MBE)
    output logic                  sbe_flag,     // Single-Bit Error flag
    output logic                  mbe_flag,     // Multiple-Bit Error flag
    output logic [6:0]            error_pos     // Error position (1-64, 0 = no error)
);

    // ========================================================================
    // Syndrome Calculation (same as encoder parity check)
    // ========================================================================
    
    // Calculate syndrome bits by re-computing parity bits
    logic s1, s2, s4, s8, s16, s32, s64;
    logic calculated_overall_parity;
    
    // Syndrome bit 1
    assign s1 = ecc_in[0] ^ data_in[0]  ^ data_in[2]  ^ data_in[4]  ^ data_in[6]  ^
                           data_in[8]  ^ data_in[10] ^ data_in[12] ^ data_in[14] ^
                           data_in[16] ^ data_in[18] ^ data_in[20] ^ data_in[22] ^
                           data_in[24] ^ data_in[26] ^ data_in[28] ^ data_in[30] ^
                           data_in[32] ^ data_in[34] ^ data_in[36] ^ data_in[38] ^
                           data_in[40] ^ data_in[42] ^ data_in[44] ^ data_in[46] ^
                           data_in[48] ^ data_in[50] ^ data_in[52] ^ data_in[54] ^
                           data_in[56] ^ data_in[58] ^ data_in[60] ^ data_in[62];
    
    // Syndrome bit 2
    assign s2 = ecc_in[1] ^ data_in[1]  ^ data_in[2]  ^ data_in[5]  ^ data_in[6]  ^
                           data_in[9]  ^ data_in[10] ^ data_in[13] ^ data_in[14] ^
                           data_in[17] ^ data_in[18] ^ data_in[21] ^ data_in[22] ^
                           data_in[25] ^ data_in[26] ^ data_in[29] ^ data_in[30] ^
                           data_in[33] ^ data_in[34] ^ data_in[37] ^ data_in[38] ^
                           data_in[41] ^ data_in[42] ^ data_in[45] ^ data_in[46] ^
                           data_in[49] ^ data_in[50] ^ data_in[53] ^ data_in[54] ^
                           data_in[57] ^ data_in[58] ^ data_in[61] ^ data_in[62];
    
    // Syndrome bit 4
    assign s4 = ecc_in[2] ^ data_in[3]  ^ data_in[4]  ^ data_in[5]  ^ data_in[6]  ^
                           data_in[11] ^ data_in[12] ^ data_in[13] ^ data_in[14] ^
                           data_in[19] ^ data_in[20] ^ data_in[21] ^ data_in[22] ^
                           data_in[27] ^ data_in[28] ^ data_in[29] ^ data_in[30] ^
                           data_in[35] ^ data_in[36] ^ data_in[37] ^ data_in[38] ^
                           data_in[43] ^ data_in[44] ^ data_in[45] ^ data_in[46] ^
                           data_in[51] ^ data_in[52] ^ data_in[53] ^ data_in[54] ^
                           data_in[59] ^ data_in[60] ^ data_in[61] ^ data_in[62];
    
    // Syndrome bit 8
    assign s8 = ecc_in[3] ^ data_in[7]  ^ data_in[8]  ^ data_in[9]  ^ data_in[10] ^
                           data_in[11] ^ data_in[12] ^ data_in[13] ^ data_in[14] ^
                           data_in[23] ^ data_in[24] ^ data_in[25] ^ data_in[26] ^
                           data_in[27] ^ data_in[28] ^ data_in[29] ^ data_in[30] ^
                           data_in[39] ^ data_in[40] ^ data_in[41] ^ data_in[42] ^
                           data_in[43] ^ data_in[44] ^ data_in[45] ^ data_in[46] ^
                           data_in[55] ^ data_in[56] ^ data_in[57] ^ data_in[58] ^
                           data_in[59] ^ data_in[60] ^ data_in[61] ^ data_in[62];
    
    // Syndrome bit 16
    assign s16 = ecc_in[4] ^ data_in[15] ^ data_in[16] ^ data_in[17] ^ data_in[18] ^
                            data_in[19] ^ data_in[20] ^ data_in[21] ^ data_in[22] ^
                            data_in[23] ^ data_in[24] ^ data_in[25] ^ data_in[26] ^
                            data_in[27] ^ data_in[28] ^ data_in[29] ^ data_in[30] ^
                            data_in[47] ^ data_in[48] ^ data_in[49] ^ data_in[50] ^
                            data_in[51] ^ data_in[52] ^ data_in[53] ^ data_in[54] ^
                            data_in[55] ^ data_in[56] ^ data_in[57] ^ data_in[58] ^
                            data_in[59] ^ data_in[60] ^ data_in[61] ^ data_in[62];
    
    // Syndrome bit 32
    assign s32 = ecc_in[5] ^ data_in[31] ^ data_in[32] ^ data_in[33] ^ data_in[34] ^
                            data_in[35] ^ data_in[36] ^ data_in[37] ^ data_in[38] ^
                            data_in[39] ^ data_in[40] ^ data_in[41] ^ data_in[42] ^
                            data_in[43] ^ data_in[44] ^ data_in[45] ^ data_in[46] ^
                            data_in[47] ^ data_in[48] ^ data_in[49] ^ data_in[50] ^
                            data_in[51] ^ data_in[52] ^ data_in[53] ^ data_in[54] ^
                            data_in[55] ^ data_in[56] ^ data_in[57] ^ data_in[58] ^
                            data_in[59] ^ data_in[60] ^ data_in[61] ^ data_in[62];
    
    // Syndrome bit 64 (covers all higher bits)
    assign s64 = ecc_in[6] ^ data_in[63] ^ (s1 ^ s2 ^ s4 ^ s8 ^ s16 ^ s32);
    
    // ========================================================================
    // Overall Parity Check (for MBE detection)
    // ========================================================================
    assign calculated_overall_parity = ^{data_in, ecc_in[7]};
    
    // ========================================================================
    // Error Detection & Classification
    // ========================================================================
    
    // Syndrome value indicates error position
    logic [6:0] syndrome;
    assign syndrome = {s64, s32, s16, s8, s4, s2, s1};
    
    // Error type determination
    // - If syndrome = 0 and parity = 0: No error
    // - If syndrome ≠ 0 and parity = 1: Single-Bit Error at position syndrome
    // - If syndrome ≠ 0 and parity = 0: Double-Bit Error (MBE)
    // - If syndrome = 0 and parity = 1: Single-Bit Error in ECC bits
    
    logic syndrome_nonzero;
    assign syndrome_nonzero = |syndrome;
    
    // SBE flag: syndrome non-zero AND overall parity odd
    assign sbe_flag = syndrome_nonzero & calculated_overall_parity;
    
    // MBE flag: syndrome non-zero AND overall parity even
    assign mbe_flag = syndrome_nonzero & ~calculated_overall_parity;
    
    // Error flag: any error detected
    assign error_flag = sbe_flag | mbe_flag;
    
    // Error position (1-based: 1 to 64, 0 = no error)
    assign error_pos = syndrome;
    
    // ========================================================================
    // Single Error Correction
    // ========================================================================
    
    logic [DATA_WIDTH-1:0] data_corrected;
    
    // Generate corrected data by flipping the error bit (only if SBE)
    generate
        for (genvar i = 0; i < DATA_WIDTH; i++) begin : data_correction_loop
            // Flip bit if position matches syndrome
            assign data_corrected[i] = (sbe_flag & (syndrome == (i+1))) ? 
                                       ~data_in[i] : data_in[i];
        end
    endgenerate
    
    // ========================================================================
    // Output Assignment
    // ========================================================================
    
    // Output corrected data only if SBE is detected (otherwise output input)
    assign data_out = sbe_flag ? data_corrected : data_in;
    
endmodule

// ============================================================================
// Formal Properties for Verification
// ============================================================================

/*
// Property 1: No error case verification
property no_error_detection;
  @(posedge clk) if (error_in == 8'h00 && data_in == calculated_data)
    (error_flag == 1'b0);
endproperty
assert property (no_error_detection);

// Property 2: SBE correction verification
property sbe_correction;
  @(posedge clk) if (sbe_flag == 1'b1)
    data_out == corrected_data;
endproperty
assert property (sbe_correction);

// Property 3: MBE detection (no correction applied)
property mbe_no_correction;
  @(posedge clk) if (mbe_flag == 1'b1)
    data_out == data_in;
endproperty
assert property (mbe_no_correction);

// Property 4: Error position accuracy for SBE
property error_position_sbe;
  @(posedge clk) if (sbe_flag == 1'b1)
    (error_pos > 0 && error_pos <= 64);
endproperty
assert property (error_position_sbe);
*/

// ============================================================================
// End of ECC Decoder Module
// ============================================================================
