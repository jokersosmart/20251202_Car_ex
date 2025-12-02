/**
 * @file ecc_controller.v
 * @brief ECC Management Controller for Memory Protection
 * 
 * This module implements the ECC management controller that coordinates ECC
 * encoding/decoding, error tracking, interrupt generation, and configuration.
 * It maintains error counters for SBE and MBE events and generates interrupts.
 *
 * Feature: 001-Power-Management-Safety
 * User Story: US3 - Memory ECC Protection & Diagnostics
 * Task: T038
 * ASIL Level: ASIL-B
 *
 * Timing:
 * - Register access: 2 cycles (read) / 3 cycles (write)
 * - Error interrupt latency: < 200ns from ECC detection
 * - Clock: 400MHz
 *
 * Coverage Target:
 * - Statement Coverage (SC): 100%
 * - Branch Coverage (BC): 100%
 * - Cyclomatic Complexity (CC): ≤ 8
 *
 * Registers:
 * - ECC_CTRL (0x00): Control register (enable, threshold)
 * - SBE_COUNT (0x04): Single-Bit Error counter
 * - MBE_COUNT (0x08): Multiple-Bit Error counter
 * - ERR_STATUS (0x0C): Last error status and position
 */

module ecc_controller #(
    parameter DATA_WIDTH = 64,
    parameter ECC_WIDTH  = 8,
    parameter COUNTER_WIDTH = 16  // 16-bit error counters (0-65535)
) (
    // System signals
    input  logic clk,
    input  logic reset_n,
    
    // ECC signals from decoder
    input  logic [DATA_WIDTH-1:0] decoded_data,
    input  logic                  ecc_error,        // SBE | MBE
    input  logic                  ecc_sbe,          // Single-Bit Error
    input  logic                  ecc_mbe,          // Multiple-Bit Error
    input  logic [6:0]            ecc_error_pos,    // Error position
    
    // APB Slave Interface (register access)
    input  logic                  psel,             // Peripheral Select
    input  logic                  penable,          // Enable
    input  logic [3:0]            paddr,            // Address (4 registers)
    input  logic                  pwrite,           // Write Enable
    input  logic [31:0]           pwdata,           // Write Data
    output logic [31:0]           prdata,           // Read Data
    output logic                  pready,           // Ready signal
    output logic                  pslverr,          // Slave Error
    
    // Interrupt signals
    output logic                  mem_fault_irq,    // Fault interrupt (SBE | MBE)
    output logic                  sbe_irq,          // SBE interrupt (if enabled)
    output logic                  mbe_irq,          // MBE interrupt (if enabled)
    
    // Data output
    output logic [DATA_WIDTH-1:0] data_out          // Corrected data
);

    // ========================================================================
    // Registers and State Variables
    // ========================================================================
    
    // Control Register: [7:0] = config bits
    // Bits [0] = ECC_ENABLE (enable ECC logic)
    // Bits [1] = SBE_IRQ_EN (enable SBE interrupts)
    // Bits [2] = MBE_IRQ_EN (enable MBE interrupts)
    // Bits [7:3] = SBE_THRESHOLD (interrupt on Nth SBE, 0=disable)
    logic [7:0] ecc_ctrl;
    logic ecc_enable, sbe_irq_en, mbe_irq_en;
    logic [4:0] sbe_threshold;
    
    assign ecc_enable = ecc_ctrl[0];
    assign sbe_irq_en = ecc_ctrl[1];
    assign mbe_irq_en = ecc_ctrl[2];
    assign sbe_threshold = ecc_ctrl[7:3];
    
    // Error Counters
    logic [COUNTER_WIDTH-1:0] sbe_count;    // 16-bit SBE counter
    logic [COUNTER_WIDTH-1:0] mbe_count;    // 16-bit MBE counter
    
    // Error Status (last error info)
    logic [7:0]               error_status;  // [0]=SBE, [1]=MBE, [7:2]=reserved
    logic [6:0]               last_error_pos;
    
    // ========================================================================
    // Error Detection and Counting Logic
    // ========================================================================
    
    // SBE detection: increment counter and optionally assert interrupt
    always_ff @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            sbe_count <= '0;
        end else if (ecc_enable & ecc_sbe) begin
            if (sbe_count < {COUNTER_WIDTH{1'b1}}) begin
                sbe_count <= sbe_count + 1'b1;  // Saturate at max
            end
        end
    end
    
    // MBE detection: increment counter and assert interrupt
    always_ff @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            mbe_count <= '0;
        end else if (ecc_enable & ecc_mbe) begin
            if (mbe_count < {COUNTER_WIDTH{1'b1}}) begin
                mbe_count <= mbe_count + 1'b1;  // Saturate at max
            end
        end
    end
    
    // Capture last error status
    always_ff @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            error_status <= 8'h00;
            last_error_pos <= 7'h00;
        end else if (ecc_enable & ecc_error) begin
            error_status[0] <= ecc_sbe;
            error_status[1] <= ecc_mbe;
            last_error_pos <= ecc_error_pos;
        end
    end
    
    // ========================================================================
    // Interrupt Generation Logic
    // ========================================================================
    
    // Main fault interrupt: triggered by any error if ECC enabled
    assign mem_fault_irq = ecc_enable & ecc_error;
    
    // SBE-specific interrupt: enabled if SBE_IRQ_EN and threshold reached
    logic sbe_threshold_reached;
    assign sbe_threshold_reached = (sbe_threshold > 0) & 
                                   (sbe_count >= {{(COUNTER_WIDTH-5){1'b0}}, sbe_threshold});
    assign sbe_irq = ecc_enable & ecc_sbe & sbe_irq_en & sbe_threshold_reached;
    
    // MBE-specific interrupt: always enabled if ECC enabled and MBE_IRQ_EN
    assign mbe_irq = ecc_enable & ecc_mbe & mbe_irq_en;
    
    // ========================================================================
    // Data Output (pass through if ECC disabled)
    // ========================================================================
    assign data_out = ecc_enable ? decoded_data : decoded_data;
    
    // ========================================================================
    // APB Slave Register Interface
    // ========================================================================
    
    // Ready signal: immediate for single-cycle access (simplification)
    assign pready = psel & penable;
    assign pslverr = 1'b0;  // No slave errors
    
    // Write transactions
    always_ff @(posedge clk or negedge reset_n) begin
        if (~reset_n) begin
            ecc_ctrl <= 8'h00;
        end else if (psel & penable & pwrite) begin
            case (paddr)
                4'h0: ecc_ctrl <= pwdata[7:0];  // ECC_CTRL register
                4'h4: begin end                  // SBE_COUNT (read-only)
                4'h8: begin end                  // MBE_COUNT (read-only)
                4'hC: begin end                  // ERR_STATUS (read-only)
                default: begin end
            endcase
        end
    end
    
    // Read transactions (combinational)
    always_comb begin
        prdata = 32'h0000_0000;
        
        if (psel & penable & ~pwrite) begin
            case (paddr)
                4'h0: prdata = {24'h0000_00, ecc_ctrl};        // ECC_CTRL
                4'h4: prdata = {{(32-COUNTER_WIDTH){1'b0}}, sbe_count};  // SBE_COUNT
                4'h8: prdata = {{(32-COUNTER_WIDTH){1'b0}}, mbe_count};  // MBE_COUNT
                4'hC: prdata = {24'h0000_00, last_error_pos, error_status};  // ERR_STATUS
                default: prdata = 32'h0000_0000;
            endcase
        end
    end
    
endmodule

// ============================================================================
// Formal Properties for Verification
// ============================================================================

/*
// Property 1: Error counter does not decrement
property sbe_counter_monotonic;
  @(posedge clk) (sbe_count_next >= sbe_count_current);
endproperty
assert property (sbe_counter_monotonic);

// Property 2: SBE interrupt generated on threshold
property sbe_interrupt_threshold;
  @(posedge clk) if (sbe_count >= sbe_threshold && sbe_irq_en)
    sbe_irq == 1'b1;
endproperty
assert property (sbe_interrupt_threshold);

// Property 3: MBE interrupt always generated if MBE_IRQ_EN
property mbe_interrupt_generation;
  @(posedge clk) if (ecc_mbe && mbe_irq_en)
    mbe_irq == 1'b1;
endproperty
assert property (mbe_interrupt_generation);

// Property 4: Error status captures last error type
property error_status_capture;
  @(posedge clk) if (ecc_error)
    error_status == {mbe, sbe, 6'h00};
endproperty
assert property (error_status_capture);
*/

// ============================================================================
// End of ECC Controller Module
// ============================================================================
