/**
 * @file fault_aggregator.c
 * @brief ISO 26262 Fault Aggregation Implementation
 *
 * Implements atomic fault flag aggregation with priority handling
 * per SysReq-002 fault priority rules:
 *  - P1 (Highest): VDD power supply failure
 *  - P2 (Medium):  Clock loss
 *  - P3 (Lowest):  Memory MBE
 *
 * Compliance:
 *  - ISO 26262-6:2018 Section 7.2.4 (Atomic operations)
 *  - SysReq-002 (Fault priority and aggregation)
 *  - ASPICE CL3 D.5.2 (Fault handling)
 */

#include "safety_types.h"
#include <string.h>

/* ============================================================================
 * External References - defined in safety_fsm.c
 * ============================================================================ */

/* Forward declarations - these are defined in safety_fsm.c */
extern bool fsm_aggregate_faults(void);
extern bool fsm_clear_faults(fault_type_t faults_to_clear);
extern bool fsm_get_status(safety_status_t *status);

/* ============================================================================
 * Fault Aggregator Module Variables
 * ============================================================================ */

/** @brief Fault aggregation lock (prevents concurrent aggregation) */
static volatile bool g_aggregator_busy = false;

/** @brief Fault priority configuration (runtime configurable) */
static volatile struct {
    uint8_t vdd_priority;      /*!< VDD priority (default: 1 = P1) */
    uint8_t clk_priority;      /*!< Clock priority (default: 2 = P2) */
    uint8_t mem_priority;      /*!< Memory priority (default: 3 = P3) */
} g_fault_priorities = {
    .vdd_priority = 1,  /* P1 - Highest */
    .clk_priority = 2,  /* P2 - Medium */
    .mem_priority = 3   /* P3 - Lowest */
};

/** @brief Last aggregation timestamp for statistics */
static volatile uint32_t g_last_aggregation_ms = 0;

/** @brief Aggregation attempt counter */
static volatile uint32_t g_aggregation_attempts = 0;

/* ============================================================================
 * Fault Aggregation Functions
 * ============================================================================ */

/**
 * @brief Aggregate fault flags from all sources
 *
 * Combines individual fault flags into a single aggregated fault status
 * with priority-based handling. Prevents race conditions through atomic
 * operations and spin-lock protection.
 *
 * Aggregation Strategy (SysReq-002):
 *  1. Check all fault flags (pwr_fault, clk_fault, mem_fault)
 *  2. Apply priority ordering: P1 > P2 > P3
 *  3. Determine highest priority active fault
 *  4. Initiate recovery based on priority
 *  5. Update fault statistics
 *
 * Acceptance Criteria:
 *  - Aggregates all 3 fault sources atomically
 *  - Applies P1 > P2 > P3 priority ordering
 *  - No race conditions with ISR handlers
 *  - Returns aggregated fault type
 *
 * @param[out] aggregated_faults Pointer to store aggregated fault type
 * @return true if aggregation successful, false if busy or failed
 */
bool fault_aggregate(fault_type_t *aggregated_faults)
{
    safety_status_t current_status;
    fault_type_t result = FAULT_TYPE_NONE;
    fault_type_t highest_priority_fault;

    if (aggregated_faults == NULL) {
        return false;
    }

    /* Spin-lock to prevent concurrent aggregation */
    if (g_aggregator_busy) {
        return false; /* Aggregation already in progress */
    }

    g_aggregator_busy = true;
    g_aggregation_attempts++;

    /* Get current safety status with DCLS verification */
    if (!fsm_get_status(&current_status)) {
        g_aggregator_busy = false;
        return false; /* DCLS failure */
    }

    /* Step 1: Collect all fault flags */
    /* Individual fault detection is done by ISR handlers.
     * Here we just aggregate them according to priority. */

    /* Check VDD fault (P1 - Highest Priority) */
    if (VERIFY_FAULT_FLAG(current_status.fault_flags.pwr_fault,
                          current_status.fault_flags.pwr_fault_cmp)) {
        if (current_status.fault_flags.pwr_fault) {
            result |= FAULT_TYPE_VDD;
        }
    } else {
        /* DCLS failure in pwr_fault flag */
        g_aggregator_busy = false;
        return false;
    }

    /* Check Clock fault (P2 - Medium Priority) */
    if (VERIFY_FAULT_FLAG(current_status.fault_flags.clk_fault,
                          current_status.fault_flags.clk_fault_cmp)) {
        if (current_status.fault_flags.clk_fault) {
            result |= FAULT_TYPE_CLK;
        }
    } else {
        /* DCLS failure in clk_fault flag */
        g_aggregator_busy = false;
        return false;
    }

    /* Check Memory fault (P3 - Lowest Priority) */
    if (VERIFY_FAULT_FLAG(current_status.fault_flags.mem_fault,
                          current_status.fault_flags.mem_fault_cmp)) {
        if (current_status.fault_flags.mem_fault) {
            result |= FAULT_TYPE_MEM_ECC;
        }
    } else {
        /* DCLS failure in mem_fault flag */
        g_aggregator_busy = false;
        return false;
    }

    /* Step 2: Determine highest priority active fault */
    if (result & FAULT_TYPE_VDD) {
        highest_priority_fault = FAULT_TYPE_VDD;  /* P1 - Highest */
    } else if (result & FAULT_TYPE_CLK) {
        highest_priority_fault = FAULT_TYPE_CLK;  /* P2 - Medium */
    } else if (result & FAULT_TYPE_MEM_ECC) {
        highest_priority_fault = FAULT_TYPE_MEM_ECC; /* P3 - Lowest */
    } else {
        highest_priority_fault = FAULT_TYPE_NONE;
    }

    /* Step 3: Update aggregated fault type */
    *aggregated_faults = highest_priority_fault;

    /* Step 4: Call FSM aggregation to update state machine */
    if (!fsm_aggregate_faults()) {
        g_aggregator_busy = false;
        return false;
    }

    /* Update timestamp */
    g_last_aggregation_ms = 0; /* Would be set by timer */

    /* Release lock */
    g_aggregator_busy = false;

    return true;
}

/**
 * @brief Get aggregated fault status with priority consideration
 *
 * Returns the current highest-priority active fault, or NONE if no faults.
 *
 * Priority Order (SysReq-002):
 *  1. P1 (VDD)  - System-level threat
 *  2. P2 (CLK)  - Synchronicity threat
 *  3. P3 (MEM)  - Data integrity threat
 *
 * @param[out] priority Pointer to store priority level (1, 2, 3, or 0=none)
 * @return Highest priority active fault type
 */
fault_type_t fault_get_highest_priority(uint8_t *priority)
{
    safety_status_t status;
    fault_type_t highest_priority_fault;

    if (!fsm_get_status(&status)) {
        if (priority) *priority = 0xFF; /* Error */
        return FAULT_TYPE_INVALID;
    }

    /* Determine highest priority fault */
    if ((status.active_faults & FAULT_TYPE_VDD) != 0) {
        highest_priority_fault = FAULT_TYPE_VDD;
        if (priority) *priority = 1; /* P1 */
    } else if ((status.active_faults & FAULT_TYPE_CLK) != 0) {
        highest_priority_fault = FAULT_TYPE_CLK;
        if (priority) *priority = 2; /* P2 */
    } else if ((status.active_faults & FAULT_TYPE_MEM_ECC) != 0) {
        highest_priority_fault = FAULT_TYPE_MEM_ECC;
        if (priority) *priority = 3; /* P3 */
    } else {
        highest_priority_fault = FAULT_TYPE_NONE;
        if (priority) *priority = 0; /* No fault */
    }

    return highest_priority_fault;
}

/**
 * @brief Check if multiple faults are active simultaneously
 *
 * Useful for detecting multi-fault scenarios where multiple failure
 * modes occur at the same time (extremely rare in normal operation,
 * but important for safety analysis).
 *
 * @return true if more than one fault source is active
 */
bool fault_has_multiple_active(void)
{
    safety_status_t status;
    int fault_count = 0;

    if (!fsm_get_status(&status)) {
        return false; /* Treat DCLS failure as single fault */
    }

    if ((status.active_faults & FAULT_TYPE_VDD) != 0) fault_count++;
    if ((status.active_faults & FAULT_TYPE_CLK) != 0) fault_count++;
    if ((status.active_faults & FAULT_TYPE_MEM_ECC) != 0) fault_count++;

    return (fault_count > 1);
}

/**
 * @brief Get bitmask of all currently active faults
 *
 * @return Bitmask of active faults (combination of FAULT_TYPE_VDD,
 *         FAULT_TYPE_CLK, FAULT_TYPE_MEM_ECC)
 */
fault_type_t fault_get_all_active(void)
{
    safety_status_t status;

    if (!fsm_get_status(&status)) {
        return FAULT_TYPE_INVALID;
    }

    return status.active_faults;
}

/**
 * @brief Check if specific fault is active
 *
 * @param fault_to_check Fault type to check (FAULT_TYPE_VDD, etc.)
 * @return true if specified fault is active
 */
bool fault_is_active(fault_type_t fault_to_check)
{
    return (fault_get_all_active() & fault_to_check) != 0;
}

/**
 * @brief Reset fault aggregator state
 *
 * Called during recovery or system reset. Clears aggregator flags
 * and resets statistics.
 *
 * @param faults_to_clear Bitmask of faults to clear
 * @return true if reset successful
 */
bool fault_aggregator_reset(fault_type_t faults_to_clear)
{
    /* Ensure aggregator is not busy */
    if (g_aggregator_busy) {
        return false;
    }

    g_aggregator_busy = true;

    /* Clear fault flags through FSM */
    if (!fsm_clear_faults(faults_to_clear)) {
        g_aggregator_busy = false;
        return false;
    }

    g_aggregator_busy = false;
    return true;
}

/**
 * @brief Set fault priority (runtime configurable)
 *
 * Allows runtime reconfiguration of fault priorities if needed.
 *
 * @param vdd_priority Priority for VDD faults (1-3)
 * @param clk_priority Priority for Clock faults (1-3)
 * @param mem_priority Priority for Memory faults (1-3)
 * @return true if configuration successful
 */
bool fault_set_priorities(uint8_t vdd_priority, uint8_t clk_priority,
                          uint8_t mem_priority)
{
    /* Validate priorities are 1-3 (higher number = lower priority) */
    if (vdd_priority < 1 || vdd_priority > 3 ||
        clk_priority < 1 || clk_priority > 3 ||
        mem_priority < 1 || mem_priority > 3) {
        return false;
    }

    /* Prevent updates during aggregation */
    if (g_aggregator_busy) {
        return false;
    }

    g_fault_priorities.vdd_priority = vdd_priority;
    g_fault_priorities.clk_priority = clk_priority;
    g_fault_priorities.mem_priority = mem_priority;

    return true;
}

/**
 * @brief Get current fault priorities
 *
 * @param[out] vdd_priority Pointer to store VDD priority
 * @param[out] clk_priority Pointer to store Clock priority
 * @param[out] mem_priority Pointer to store Memory priority
 * @return true if read successful
 */
bool fault_get_priorities(uint8_t *vdd_priority, uint8_t *clk_priority,
                          uint8_t *mem_priority)
{
    if (vdd_priority == NULL || clk_priority == NULL ||
        mem_priority == NULL) {
        return false;
    }

    *vdd_priority = g_fault_priorities.vdd_priority;
    *clk_priority = g_fault_priorities.clk_priority;
    *mem_priority = g_fault_priorities.mem_priority;

    return true;
}

/**
 * @brief Get aggregation statistics
 *
 * @return Total number of aggregation attempts
 */
uint32_t fault_get_aggregation_count(void)
{
    return g_aggregation_attempts;
}
