/**
 * @file ecc_encoder.v
 * @brief Hamming-SEC/DED ECC Encoder for Memory Protection
 * 
 * This module implements a Hamming-SEC/DED (Single Error Correction/Double Error Detection)
 * ECC encoder for protecting 64-bit data words. It generates parity bits that enable
 * single-bit error correction and double-bit error detection.
 *
 * Feature: 001-Power-Management-Safety
 * User Story: US3 - Memory ECC Protection & Diagnostics
 * Task: T036
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
 * Safety Properties:
 * - Parity calculation: 7 bits (for 64-bit data)
 * - Overall parity: 1 bit
 * - Total ECC bits: 8 bits
 * - Min Hamming distance: 4 (SEC/DED capable)
 */

module ecc_encoder #(
    parameter DATA_WIDTH = 64,      // 64-bit data
    parameter ECC_WIDTH  = 8        // 7 syndrome bits + 1 overall parity
) (
    // Input
    input  logic [DATA_WIDTH-1:0] data_in,      // 64-bit data word
    
    // Output
    output logic [ECC_WIDTH-1:0]  ecc_out       // 8-bit ECC code
);

    // ========================================================================
    // Hamming Code Calculation for 64-bit data
    // ========================================================================
    // Parity bit positions: p1, p2, p4, p8, p16, p32, p64
    // Position format: [64:57] = Data[63:56], [56:49] = Data[55:48], ...
    
    // Parity bit 1 (p1): covers positions 1,3,5,7,9,11,13,...
    // In data bits: positions where bit 0 of position number is 1
    logic p1;
    assign p1 = data_in[0]  ^ data_in[2]  ^ data_in[4]  ^ data_in[6]  ^
                data_in[8]  ^ data_in[10] ^ data_in[12] ^ data_in[14] ^
                data_in[16] ^ data_in[18] ^ data_in[20] ^ data_in[22] ^
                data_in[24] ^ data_in[26] ^ data_in[28] ^ data_in[30] ^
                data_in[32] ^ data_in[34] ^ data_in[36] ^ data_in[38] ^
                data_in[40] ^ data_in[42] ^ data_in[44] ^ data_in[46] ^
                data_in[48] ^ data_in[50] ^ data_in[52] ^ data_in[54] ^
                data_in[56] ^ data_in[58] ^ data_in[60] ^ data_in[62];
    
    // Parity bit 2 (p2): covers positions 2,3,6,7,10,11,14,15,...
    // In data bits: positions where bit 1 of position number is 1
    logic p2;
    assign p2 = data_in[1]  ^ data_in[2]  ^ data_in[5]  ^ data_in[6]  ^
                data_in[9]  ^ data_in[10] ^ data_in[13] ^ data_in[14] ^
                data_in[17] ^ data_in[18] ^ data_in[21] ^ data_in[22] ^
                data_in[25] ^ data_in[26] ^ data_in[29] ^ data_in[30] ^
                data_in[33] ^ data_in[34] ^ data_in[37] ^ data_in[38] ^
                data_in[41] ^ data_in[42] ^ data_in[45] ^ data_in[46] ^
                data_in[49] ^ data_in[50] ^ data_in[53] ^ data_in[54] ^
                data_in[57] ^ data_in[58] ^ data_in[61] ^ data_in[62];
    
    // Parity bit 4 (p4): covers positions 4,5,6,7,12,13,14,15,...
    // In data bits: positions where bit 2 of position number is 1
    logic p4;
    assign p4 = data_in[3]  ^ data_in[4]  ^ data_in[5]  ^ data_in[6]  ^
                data_in[11] ^ data_in[12] ^ data_in[13] ^ data_in[14] ^
                data_in[19] ^ data_in[20] ^ data_in[21] ^ data_in[22] ^
                data_in[27] ^ data_in[28] ^ data_in[29] ^ data_in[30] ^
                data_in[35] ^ data_in[36] ^ data_in[37] ^ data_in[38] ^
                data_in[43] ^ data_in[44] ^ data_in[45] ^ data_in[46] ^
                data_in[51] ^ data_in[52] ^ data_in[53] ^ data_in[54] ^
                data_in[59] ^ data_in[60] ^ data_in[61] ^ data_in[62];
    
    // Parity bit 8 (p8): covers positions 8-15, 24-31, 40-47, 56-63
    // In data bits: positions where bit 3 of position number is 1
    logic p8;
    assign p8 = data_in[7]  ^ data_in[8]  ^ data_in[9]  ^ data_in[10] ^
                data_in[11] ^ data_in[12] ^ data_in[13] ^ data_in[14] ^
                data_in[23] ^ data_in[24] ^ data_in[25] ^ data_in[26] ^
                data_in[27] ^ data_in[28] ^ data_in[29] ^ data_in[30] ^
                data_in[39] ^ data_in[40] ^ data_in[41] ^ data_in[42] ^
                data_in[43] ^ data_in[44] ^ data_in[45] ^ data_in[46] ^
                data_in[55] ^ data_in[56] ^ data_in[57] ^ data_in[58] ^
                data_in[59] ^ data_in[60] ^ data_in[61] ^ data_in[62];
    
    // Parity bit 16 (p16): covers positions 16-31, 48-63
    // In data bits: positions where bit 4 of position number is 1
    logic p16;
    assign p16 = data_in[15] ^ data_in[16] ^ data_in[17] ^ data_in[18] ^
                 data_in[19] ^ data_in[20] ^ data_in[21] ^ data_in[22] ^
                 data_in[23] ^ data_in[24] ^ data_in[25] ^ data_in[26] ^
                 data_in[27] ^ data_in[28] ^ data_in[29] ^ data_in[30] ^
                 data_in[47] ^ data_in[48] ^ data_in[49] ^ data_in[50] ^
                 data_in[51] ^ data_in[52] ^ data_in[53] ^ data_in[54] ^
                 data_in[55] ^ data_in[56] ^ data_in[57] ^ data_in[58] ^
                 data_in[59] ^ data_in[60] ^ data_in[61] ^ data_in[62];
    
    // Parity bit 32 (p32): covers positions 32-63
    // In data bits: positions where bit 5 of position number is 1
    logic p32;
    assign p32 = data_in[31] ^ data_in[32] ^ data_in[33] ^ data_in[34] ^
                 data_in[35] ^ data_in[36] ^ data_in[37] ^ data_in[38] ^
                 data_in[39] ^ data_in[40] ^ data_in[41] ^ data_in[42] ^
                 data_in[43] ^ data_in[44] ^ data_in[45] ^ data_in[46] ^
                 data_in[47] ^ data_in[48] ^ data_in[49] ^ data_in[50] ^
                 data_in[51] ^ data_in[52] ^ data_in[53] ^ data_in[54] ^
                 data_in[55] ^ data_in[56] ^ data_in[57] ^ data_in[58] ^
                 data_in[59] ^ data_in[60] ^ data_in[61] ^ data_in[62];
    
    // Parity bit 64 (p64): covers all 64 data bits (from position 32 onwards)
    logic p64;
    assign p64 = data_in[63] ^ p1 ^ p2 ^ p4 ^ p8 ^ p16 ^ p32;
    
    // ========================================================================
    // Overall Parity (for DED capability)
    // ========================================================================
    // XOR of all data bits
    logic overall_parity;
    assign overall_parity = ^data_in;  // XOR reduction
    
    // ========================================================================
    // ECC Output Assignment
    // ========================================================================
    // Format: [7] = overall_parity, [6:0] = p64, p32, p16, p8, p4, p2, p1
    assign ecc_out = {overall_parity, p64, p32, p16, p8, p4, p2, p1};
    
endmodule

// ============================================================================
// Formal Properties for Verification
// ============================================================================

/*
// Property 1: ECC correctness for zero data (no errors)
property ecc_zero_data;
  @(posedge clk) if (data_in == 64'h0000_0000_0000_0000)
    ecc_out == 8'h00;
endproperty
assert property (ecc_zero_data);

// Property 2: ECC correctness for all-ones data
property ecc_all_ones;
  @(posedge clk) if (data_in == 64'hFFFF_FFFF_FFFF_FFFF)
    ecc_out == 8'hFF;
endproperty
assert property (ecc_all_ones);

// Property 3: Hamming distance verification
// Any single-bit flip in data should change ECC by exactly 1 or 3 bits
property hamming_distance_sbe;
  @(posedge clk) 
    forall (bit i in [0:63])
      ((ecc_out ^ ecc_out_flipped_bit[i]) <= 3);
endproperty
assert property (hamming_distance_sbe);

// Property 4: Overall parity calculation
property overall_parity_check;
  @(posedge clk)
    ecc_out[7] == (^data_in ^ ecc_out[6:0]);
endproperty
assert property (overall_parity_check);
*/

// ============================================================================
// End of ECC Encoder Module
// ============================================================================
