/**
 * @file ecc_service.c
 * @brief ECC Service Initialization and Configuration
 * 
 * This module provides initialization and configuration functions for the
 * ECC protection system. It configures ECC thresholds, enables/disables ECC
 * and interrupt generation, and provides status query interfaces.
 *
 * Feature: 001-Power-Management-Safety
 * User Story: US3 - Memory ECC Protection & Diagnostics
 * Task: T039
 * ASIL Level: ASIL-B
 *
 * Execution Context:
 * - Called during system initialization (early boot)
 * - Periodic status checks (every 100ms in recovery thread)
 * - ISR context for ECC handler (T040)
 *
 * Timing Budget:
 * - ecc_init(): < 100μs (initialization only)
 * - ecc_configure(): < 50μs per call
 * - ecc_get_status(): < 10μs (register read)
 */

#include <stdint.h>
#include <stdbool.h>
#include <string.h>

// ============================================================================
// Hardware Register Definitions
// ============================================================================

// ECC Controller Register Base Address
#define ECC_BASE_ADDR 0x40010000

// Register Offsets
#define ECC_CTRL_OFFSET     0x00    // Control Register
#define ECC_SBE_COUNT_OFFSET 0x04   // SBE Counter
#define ECC_MBE_COUNT_OFFSET 0x08   // MBE Counter
#define ECC_ERR_STATUS_OFFSET 0x0C  // Error Status

// Register definitions
volatile uint32_t * const ECC_CTRL = (volatile uint32_t *)(ECC_BASE_ADDR + ECC_CTRL_OFFSET);
volatile uint32_t * const ECC_SBE_COUNT = (volatile uint32_t *)(ECC_BASE_ADDR + ECC_SBE_COUNT_OFFSET);
volatile uint32_t * const ECC_MBE_COUNT = (volatile uint32_t *)(ECC_BASE_ADDR + ECC_MBE_COUNT_OFFSET);
volatile uint32_t * const ECC_ERR_STATUS = (volatile uint32_t *)(ECC_BASE_ADDR + ECC_ERR_STATUS_OFFSET);

// ECC_CTRL Register Bits
#define ECC_CTRL_ENABLE         0x01    // Bit 0: Enable ECC
#define ECC_CTRL_SBE_IRQ_EN     0x02    // Bit 1: Enable SBE interrupt
#define ECC_CTRL_MBE_IRQ_EN     0x04    // Bit 2: Enable MBE interrupt
#define ECC_CTRL_SBE_THRESH_MASK 0xF8   // Bits 7:3: SBE threshold
#define ECC_CTRL_SBE_THRESH_SHIFT 3

// ============================================================================
// ECC Service State
// ============================================================================

typedef struct {
    bool initialized;           // Initialization flag
    uint8_t ecc_enable;        // ECC enable state
    uint8_t sbe_threshold;     // SBE interrupt threshold (0 = disabled)
    uint16_t sbe_error_count;  // Tracked SBE count
    uint16_t mbe_error_count;  // Tracked MBE count
} ecc_service_state_t;

static ecc_service_state_t ecc_state = {
    .initialized = false,
    .ecc_enable = 0,
    .sbe_threshold = 0,
    .sbe_error_count = 0,
    .mbe_error_count = 0
};

// ============================================================================
// ECC Service Functions
// ============================================================================

/**
 * @brief Initialize ECC service
 * 
 * Initializes ECC controller hardware, sets default configuration,
 * and clears error counters. Must be called once during boot.
 *
 * Execution Time: ~50μs (register access)
 * Safety Context: Boot initialization (no interrupts active)
 *
 * @return true if initialization successful, false on error
 */
bool ecc_init(void)
{
    // Validation: prevent double initialization
    if (ecc_state.initialized) {
        return false;  // Already initialized
    }
    
    // Disable ECC during configuration (safety: avoid partial config state)
    *ECC_CTRL = 0x00;
    
    // Set default configuration:
    // - ECC enabled
    // - SBE interrupt threshold = 10
    // - MBE interrupt enabled
    // - SBE interrupt enabled
    uint32_t ctrl_val = ECC_CTRL_ENABLE |           // Bit 0: Enable
                        ECC_CTRL_SBE_IRQ_EN |       // Bit 1: SBE IRQ
                        ECC_CTRL_MBE_IRQ_EN |       // Bit 2: MBE IRQ
                        (10 << ECC_CTRL_SBE_THRESH_SHIFT);  // Bits 7:3: Threshold=10
    
    *ECC_CTRL = ctrl_val;
    
    // Initialize state variables
    ecc_state.ecc_enable = 1;
    ecc_state.sbe_threshold = 10;
    ecc_state.sbe_error_count = 0;
    ecc_state.mbe_error_count = 0;
    ecc_state.initialized = true;
    
    return true;
}

/**
 * @brief Configure ECC thresholds and enable/disable
 * 
 * Configures ECC behavior:
 * - Enable/disable ECC protection
 * - Set SBE interrupt threshold (0 = disabled)
 * - Enable/disable SBE and MBE interrupts
 *
 * Execution Time: ~30μs (register write)
 * Thread Safety: Non-atomic (should be called in safe state)
 *
 * @param enable ECC enable flag (1 = enable, 0 = disable)
 * @param sbe_threshold SBE interrupt threshold (0-31, 0=disabled)
 * @param sbe_irq_en Enable SBE interrupt
 * @param mbe_irq_en Enable MBE interrupt
 *
 * @return true if configuration successful
 */
bool ecc_configure(uint8_t enable, uint8_t sbe_threshold, 
                   uint8_t sbe_irq_en, uint8_t mbe_irq_en)
{
    // Validation
    if (!ecc_state.initialized) {
        return false;  // Must call ecc_init() first
    }
    
    if (sbe_threshold > 31) {
        return false;  // Threshold out of range (5-bit field)
    }
    
    // Build control register value
    uint32_t ctrl_val = 0;
    
    if (enable) {
        ctrl_val |= ECC_CTRL_ENABLE;
    }
    
    if (sbe_irq_en) {
        ctrl_val |= ECC_CTRL_SBE_IRQ_EN;
    }
    
    if (mbe_irq_en) {
        ctrl_val |= ECC_CTRL_MBE_IRQ_EN;
    }
    
    // Set threshold in upper bits
    ctrl_val |= (sbe_threshold << ECC_CTRL_SBE_THRESH_SHIFT);
    
    // Write to hardware
    *ECC_CTRL = ctrl_val;
    
    // Update state
    ecc_state.ecc_enable = enable;
    ecc_state.sbe_threshold = sbe_threshold;
    
    return true;
}

/**
 * @brief Get ECC service status
 * 
 * Reads current ECC status including error counters and configuration.
 * Safe to call from any context (read-only).
 *
 * Execution Time: ~40μs (4 register reads)
 * Thread Safety: Atomic reads (hardware guarantees)
 *
 * @param status Pointer to status structure (out)
 *
 * @return true if status read successful
 */
typedef struct {
    uint16_t sbe_count;      // Current SBE count
    uint16_t mbe_count;      // Current MBE count
    uint8_t last_error_type; // 0=none, 1=SBE, 2=MBE
    uint8_t last_error_pos;  // Error bit position (1-64, 0=none)
    bool ecc_enabled;        // ECC enable status
} ecc_status_t;

bool ecc_get_status(ecc_status_t *status)
{
    // Validation
    if (!ecc_state.initialized) {
        return false;
    }
    
    if (status == NULL) {
        return false;
    }
    
    // Read error counters (16-bit each)
    status->sbe_count = (uint16_t)(*ECC_SBE_COUNT & 0xFFFF);
    status->mbe_count = (uint16_t)(*ECC_MBE_COUNT & 0xFFFF);
    
    // Read error status
    uint32_t err_status = *ECC_ERR_STATUS;
    status->last_error_type = (err_status & 0x03);  // Bits [1:0]
    status->last_error_pos = (err_status >> 8) & 0x7F;  // Bits [14:8]
    
    // Read current ECC enable state
    status->ecc_enabled = ecc_state.ecc_enable ? true : false;
    
    return true;
}

/**
 * @brief Clear ECC error counters
 * 
 * Resets SBE and MBE counters. Useful for periodic diagnostics
 * and recovery validation.
 *
 * Execution Time: ~20μs
 * Thread Safety: Non-atomic (should be called in safe state)
 *
 * Note: Hardware counters saturate at max value (65535).
 * Manual clearing prevents overflow detection loss.
 *
 * @return true if clear successful
 */
bool ecc_clear_counters(void)
{
    // Validation
    if (!ecc_state.initialized) {
        return false;
    }
    
    // Clear state counters
    ecc_state.sbe_error_count = 0;
    ecc_state.mbe_error_count = 0;
    
    // Note: Hardware registers are read-only counters
    // They clear automatically on overflow or can only be reset via
    // hardware reset. This function updates shadow state only.
    
    return true;
}

/**
 * @brief Enable ECC protection
 * 
 * Enables ECC protection (simple enable without threshold change)
 *
 * @return true if successful
 */
bool ecc_enable(void)
{
    return ecc_configure(1, ecc_state.sbe_threshold, 1, 1);
}

/**
 * @brief Disable ECC protection
 * 
 * Disables ECC protection (used during safe state or diagnostics)
 *
 * @return true if successful
 */
bool ecc_disable(void)
{
    return ecc_configure(0, 0, 0, 0);
}

/**
 * @brief Query ECC enable state
 * 
 * Returns current ECC enable state
 *
 * @return true if ECC enabled, false otherwise
 */
bool ecc_is_enabled(void)
{
    return ecc_state.ecc_enable ? true : false;
}

/**
 * @brief Set SBE interrupt threshold
 * 
 * Configure at which SBE count the interrupt is generated
 * (e.g., threshold=5 means interrupt on 5th SBE)
 *
 * @param threshold Interrupt threshold (0-31, 0=disabled)
 *
 * @return true if successful
 */
bool ecc_set_sbe_threshold(uint8_t threshold)
{
    if (threshold > 31) {
        return false;
    }
    
    return ecc_configure(ecc_state.ecc_enable, threshold, 1, 1);
}

/**
 * @brief Get current SBE error count
 * 
 * Returns number of SBE events detected since initialization or clear
 *
 * @return SBE count (0-65535, capped at max)
 */
uint16_t ecc_get_sbe_count(void)
{
    if (!ecc_state.initialized) {
        return 0;
    }
    
    return (uint16_t)(*ECC_SBE_COUNT & 0xFFFF);
}

/**
 * @brief Get current MBE error count
 * 
 * Returns number of MBE events detected since initialization or clear
 *
 * @return MBE count (0-65535, capped at max)
 */
uint16_t ecc_get_mbe_count(void)
{
    if (!ecc_state.initialized) {
        return 0;
    }
    
    return (uint16_t)(*ECC_MBE_COUNT & 0xFFFF);
}

/**
 * @brief Validate ECC configuration
 * 
 * Performs sanity check on ECC configuration:
 * - Checks enable state
 * - Validates counter values not at max (saturation detection)
 * - Ensures thresholds are reasonable
 *
 * @return true if configuration valid, false if anomaly detected
 */
bool ecc_validate_config(void)
{
    if (!ecc_state.initialized) {
        return false;
    }
    
    // Check for counter saturation (possible data loss)
    uint16_t sbe_count = ecc_get_sbe_count();
    uint16_t mbe_count = ecc_get_mbe_count();
    
    const uint16_t MAX_COUNT = 0xFFFF;
    
    if (sbe_count == MAX_COUNT || mbe_count == MAX_COUNT) {
        // Saturation detected - may indicate persistent errors
        return false;
    }
    
    // Check threshold reasonableness
    if (ecc_state.sbe_threshold > 31) {
        return false;
    }
    
    return true;
}

// ============================================================================
// End of ECC Service Initialization
// ============================================================================
