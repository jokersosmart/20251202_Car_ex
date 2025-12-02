/**
 * @file safety_types.h
 * @brief ISO 26262 Safety-Critical Type Definitions
 *
 * This header defines all safety-critical data types, enumerations, and
 * structures required for the Power Management Safety System.
 * All types use volatile qualifiers where appropriate to prevent
 * compiler optimizations that could mask safety violations.
 *
 * Compliance:
 *  - ISO 26262-6:2018 Section 7.5.3 (Simple types)
 *  - ASPICE CL3 D.4.2 (Type-safe interfaces)
 */

#ifndef SAFETY_TYPES_H
#define SAFETY_TYPES_H

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/* ============================================================================
 * Safety Status Enumeration - used in FSM state tracking
 * ============================================================================ */

/**
 * @enum safety_state_t
 * @brief System safety state enumeration
 *
 * Defines the 5 discrete states of the safety system FSM per TSR-002.
 * Transitions are strictly controlled and monitored.
 */
typedef enum {
    SAFETY_STATE_INIT = 0x55,        /*!< Initialization state (power-up) */
    SAFETY_STATE_NORMAL = 0xAA,      /*!< Normal operation state */
    SAFETY_STATE_FAULT = 0xCC,       /*!< Fault detected state */
    SAFETY_STATE_SAFE_STATE = 0x33,  /*!< Safe state (transition in progress) */
    SAFETY_STATE_RECOVERY = 0x99,    /*!< Recovery operation in progress */
    SAFETY_STATE_INVALID = 0xFF      /*!< Invalid state (error indicator) */
} safety_state_t;

/**
 * @enum fault_type_t
 * @brief Fault source type enumeration (P1-P3 priority levels)
 *
 * Defines fault types with encoded priority per SysReq-002:
 *  - P1 (0x01): VDD power supply failure - system-level threat
 *  - P2 (0x02): Clock loss - synchronicity threat
 *  - P3 (0x04): Memory MBE - data integrity threat
 */
typedef enum {
    FAULT_TYPE_NONE = 0x00,          /*!< No fault */
    FAULT_TYPE_VDD = 0x01,           /*!< Power supply fault (P1) */
    FAULT_TYPE_CLK = 0x02,           /*!< Clock fault (P2) */
    FAULT_TYPE_MEM_ECC = 0x04,       /*!< Memory ECC fault (P3) */
    FAULT_TYPE_MULTIPLE = 0x07,      /*!< Multiple faults aggregated */
    FAULT_TYPE_INVALID = 0xFF        /*!< Invalid fault type */
} fault_type_t;

/**
 * @enum recovery_result_t
 * @brief Recovery operation result enumeration
 */
typedef enum {
    RECOVERY_PENDING = 0x00,         /*!< Recovery in progress */
    RECOVERY_SUCCESS = 0xAA,         /*!< Recovery successful */
    RECOVERY_FAILED = 0x55,          /*!< Recovery failed */
    RECOVERY_TIMEOUT = 0xCC,         /*!< Recovery timeout */
    RECOVERY_INVALID = 0xFF          /*!< Invalid state */
} recovery_result_t;

/* ============================================================================
 * Fault Flags Structure - volatile to prevent CSE optimizations
 * ============================================================================ */

/**
 * @struct fault_flags_t
 * @brief Individual fault flags for each fault source
 *
 * Per ISO 26262-6:2018, all flags are volatile to prevent the compiler
 * from eliminating supposedly "redundant" flag checks.
 * Each flag is protected by a counter-flag for dual-point detection.
 */
typedef struct {
    volatile uint8_t pwr_fault;      /*!< VDD power supply fault flag (P1) */
    volatile uint8_t pwr_fault_cmp;  /*!< Complement: ~pwr_fault */
    
    volatile uint8_t clk_fault;      /*!< Clock loss fault flag (P2) */
    volatile uint8_t clk_fault_cmp;  /*!< Complement: ~clk_fault */
    
    volatile uint8_t mem_fault;      /*!< Memory ECC fault flag (P3) */
    volatile uint8_t mem_fault_cmp;  /*!< Complement: ~mem_fault */
    
    volatile uint8_t reserved[2];    /*!< Reserved for future use */
} fault_flags_t;

/* ============================================================================
 * Safety Status Structure - core safety information
 * ============================================================================ */

/**
 * @struct safety_status_t
 * @brief Current safety system status and mode
 *
 * Contains the current state, fault information, and recovery status.
 * Used by monitoring components to query system health.
 */
typedef struct {
    volatile safety_state_t current_state;    /*!< Current FSM state */
    volatile safety_state_t current_state_cmp; /*!< Complement for DCLS */
    
    volatile fault_type_t active_faults;      /*!< Bitmask of active faults */
    volatile fault_type_t active_faults_cmp;  /*!< Complement */
    
    volatile recovery_result_t recovery_status; /*!< Last recovery result */
    volatile uint16_t fault_count;            /*!< Total fault count */
    
    volatile uint32_t timestamp_ms;           /*!< Last fault timestamp (ms) */
    volatile fault_flags_t fault_flags;       /*!< Individual fault flags */
} safety_status_t;

/* ============================================================================
 * Fault Statistics Structure - for diagnostic coverage calculation
 * ============================================================================ */

/**
 * @struct fault_statistics_t
 * @brief Cumulative fault statistics for DC calculation
 *
 * Tracks fault occurrences by type for diagnostic coverage (DC)
 * calculation per ISO 26262-1 Annex C.
 *
 * DC = (Number of detected faults) / (Potential faults + detected faults)
 */
typedef struct {
    volatile uint32_t vdd_faults_detected;     /*!< VDD fault detections */
    volatile uint32_t vdd_faults_undetected;   /*!< VDD faults not detected (if any) */
    
    volatile uint32_t clk_faults_detected;     /*!< Clock fault detections */
    volatile uint32_t clk_faults_undetected;   /*!< Clock faults not detected */
    
    volatile uint32_t mem_faults_detected;     /*!< Memory fault detections */
    volatile uint32_t mem_faults_undetected;   /*!< Memory faults not detected */
    
    volatile uint32_t recovery_successes;      /*!< Successful recoveries */
    volatile uint32_t recovery_failures;       /*!< Recovery failures */
    
    volatile uint64_t uptime_ms;               /*!< System uptime in ms */
    volatile uint32_t last_update_ms;          /*!< Last update timestamp */
} fault_statistics_t;

/* ============================================================================
 * Recovery Configuration Structure - used for recovery parameter setup
 * ============================================================================ */

/**
 * @struct recovery_config_t
 * @brief Recovery operation configuration parameters
 *
 * Configurable parameters for fault recovery per SysReq-002:
 *  - Recovery timeout: 100ms (external signal timeout)
 *  - Retry attempts: configurable
 *  - Safe state entry delay: < 10ms
 */
typedef struct {
    volatile uint32_t recovery_timeout_ms;    /*!< Recovery timeout (100ms default) */
    volatile uint8_t max_retry_attempts;      /*!< Maximum recovery attempts */
    volatile uint8_t safe_state_delay_ms;     /*!< Safe state entry delay < 10ms */
    volatile uint8_t external_signal_timeout_ms; /*!< External signal timeout 100ms */
    
    volatile bool enable_vdd_recovery;        /*!< Enable VDD recovery */
    volatile bool enable_clk_recovery;        /*!< Enable clock recovery */
    volatile bool enable_mem_recovery;        /*!< Enable memory recovery */
    
    volatile uint8_t reserved[5];             /*!< Reserved for future use */
} recovery_config_t;

/* ============================================================================
 * ISR Entry Point Structure - for interrupt vector configuration
 * ============================================================================ */

/**
 * @struct isr_entry_t
 * @brief ISR entry configuration structure
 *
 * Defines ISR entry point function pointers for each fault source.
 * Each ISR must:
 *  1. Execute within 5μs (TSR-002)
 *  2. Be re-entrant (support nested interrupts)
 *  3. Set corresponding fault flag atomically
 */
typedef struct {
    void (*vdd_isr)(void);      /*!< VDD fault ISR entry point */
    void (*clk_isr)(void);      /*!< Clock fault ISR entry point */
    void (*mem_isr)(void);      /*!< Memory fault ISR entry point */
} isr_entry_t;

/* ============================================================================
 * Global Safety Variables - volatile to prevent optimization
 * ============================================================================ */

/**
 * @brief Global safety status (exported by safety module)
 *
 * This is the main safety status variable shared between:
 *  - ISR handlers (write-only on specific fields)
 *  - Safety FSM (read/write)
 *  - Application layer (read-only)
 *
 * Declaration: extern volatile safety_status_t g_safety_status;
 */

/**
 * @brief Global fault statistics (exported by fault_statistics module)
 *
 * Updated by fault aggregator and queried for DC calculation.
 *
 * Declaration: extern volatile fault_statistics_t g_fault_stats;
 */

/**
 * @brief Global fault flags (fast access to individual fault flags)
 *
 * Used by ISR handlers for rapid fault flag manipulation.
 *
 * Declaration: extern volatile fault_flags_t g_fault_flags;
 */

/* ============================================================================
 * Helper Macros for DCLS (Dual-Channel Logic Signature) Verification
 * ============================================================================ */

/**
 * @def VERIFY_FAULT_FLAG(flag, cmp_flag)
 * @brief Verify dual-point detection of fault flags
 *
 * Per ISO 26262-6:2018 Section 7.6.6, verifies that flag and its
 * complement are consistent (DCLS check).
 *
 * @param flag Main fault flag value
 * @param cmp_flag Complement fault flag value
 * @return true if flags are consistent, false if DCLS failure detected
 */
#define VERIFY_FAULT_FLAG(flag, cmp_flag) \
    (((flag) ^ (cmp_flag)) == 0xFF)

/**
 * @def VERIFY_STATE(state, state_cmp)
 * @brief Verify dual-point detection of state variable
 *
 * Verifies state and complement consistency for FSM protection.
 *
 * @param state Main state value
 * @param state_cmp Complement state value
 * @return true if states are consistent, false if DCLS failure detected
 */
#define VERIFY_STATE(state, state_cmp) \
    (((state) ^ (state_cmp)) == 0xFF)

/* ============================================================================
 * Inline Helper Functions
 * ============================================================================ */

/**
 * @brief Check if any fault is active
 *
 * @param faults Fault bitmask to check
 * @return true if any fault is set, false otherwise
 */
static inline bool has_active_faults(fault_type_t faults)
{
    return (faults != FAULT_TYPE_NONE);
}

/**
 * @brief Check if VDD fault is active
 *
 * @param faults Fault bitmask
 * @return true if VDD fault is set
 */
static inline bool is_vdd_fault_active(fault_type_t faults)
{
    return ((faults & FAULT_TYPE_VDD) != 0);
}

/**
 * @brief Check if Clock fault is active
 *
 * @param faults Fault bitmask
 * @return true if Clock fault is set
 */
static inline bool is_clk_fault_active(fault_type_t faults)
{
    return ((faults & FAULT_TYPE_CLK) != 0);
}

/**
 * @brief Check if Memory fault is active
 *
 * @param faults Fault bitmask
 * @return true if Memory fault is set
 */
static inline bool is_mem_fault_active(fault_type_t faults)
{
    return ((faults & FAULT_TYPE_MEM_ECC) != 0);
}

#ifdef __cplusplus
}
#endif

#endif /* SAFETY_TYPES_H */
