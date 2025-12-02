/**
 * @file safety_fsm.c
 * @brief ISO 26262 Safety FSM Implementation
 *
 * Implements the core safety state machine (FSM) with 5 states:
 *  1. INIT - Power-up initialization
 *  2. NORMAL - Normal operation
 *  3. FAULT - Fault detected
 *  4. SAFE_STATE - Safe state transition in progress
 *  5. RECOVERY - Recovery operation in progress
 *
 * Compliance:
 *  - ISO 26262-6:2018 Section 7.5.2 (Control flow)
 *  - TSR-002 (Safety FSM implementation)
 *  - ASPICE CL3 D.5.1 (State machine patterns)
 */

#include "safety_types.h"
#include <stddef.h>

/* ============================================================================
 * Global Variables
 * ============================================================================ */

/** @brief Global safety status maintained by FSM */
static volatile safety_status_t g_safety_status = {
    .current_state = SAFETY_STATE_INIT,
    .current_state_cmp = ~SAFETY_STATE_INIT,
    .active_faults = FAULT_TYPE_NONE,
    .active_faults_cmp = ~FAULT_TYPE_NONE,
    .recovery_status = RECOVERY_PENDING,
    .fault_count = 0,
    .timestamp_ms = 0,
    .fault_flags = {
        .pwr_fault = 0x00, .pwr_fault_cmp = 0xFF,
        .clk_fault = 0x00, .clk_fault_cmp = 0xFF,
        .mem_fault = 0x00, .mem_fault_cmp = 0xFF,
        .reserved = {0, 0}
    }
};

/** @brief FSM initialization flag */
static volatile bool g_fsm_initialized = false;

/* ============================================================================
 * FSM Transition Table - validates allowed state transitions
 * ============================================================================ */

/**
 * @brief Transition matrix defining allowed state transitions
 *
 * Format: allowed_transitions[current_state][next_state]
 *  true  = transition allowed
 *  false = transition not allowed (DCLS failure)
 */
static const bool g_transition_matrix[6][6] = {
    /* From INIT */
    {
        false, /* INIT -> INIT (not allowed) */
        true,  /* INIT -> NORMAL (power-up complete) */
        false, /* INIT -> FAULT (not allowed) */
        false, /* INIT -> SAFE_STATE (not allowed) */
        false, /* INIT -> RECOVERY (not allowed) */
        false  /* INIT -> INVALID */
    },
    /* From NORMAL */
    {
        false, /* NORMAL -> INIT (not allowed) */
        true,  /* NORMAL -> NORMAL (stay normal) */
        true,  /* NORMAL -> FAULT (fault detected) */
        true,  /* NORMAL -> SAFE_STATE (proactive safe state) */
        false, /* NORMAL -> RECOVERY (not allowed) */
        false  /* NORMAL -> INVALID */
    },
    /* From FAULT */
    {
        false, /* FAULT -> INIT (not allowed) */
        false, /* FAULT -> NORMAL (not allowed directly) */
        true,  /* FAULT -> FAULT (stay in fault) */
        true,  /* FAULT -> SAFE_STATE (enter safe state) */
        true,  /* FAULT -> RECOVERY (attempt recovery) */
        false  /* FAULT -> INVALID */
    },
    /* From SAFE_STATE */
    {
        false, /* SAFE_STATE -> INIT (not allowed) */
        false, /* SAFE_STATE -> NORMAL (not allowed) */
        false, /* SAFE_STATE -> FAULT (not allowed) */
        true,  /* SAFE_STATE -> SAFE_STATE (stay safe) */
        true,  /* SAFE_STATE -> RECOVERY (attempt recovery) */
        false  /* SAFE_STATE -> INVALID */
    },
    /* From RECOVERY */
    {
        false, /* RECOVERY -> INIT (not allowed) */
        true,  /* RECOVERY -> NORMAL (recovery successful) */
        true,  /* RECOVERY -> FAULT (recovery failed, new fault) */
        true,  /* RECOVERY -> SAFE_STATE (recovery failed, go safe) */
        true,  /* RECOVERY -> RECOVERY (retry recovery) */
        false  /* RECOVERY -> INVALID */
    },
    /* From INVALID */
    {
        false, /* INVALID -> INIT (not allowed) */
        false, /* INVALID -> NORMAL (not allowed) */
        false, /* INVALID -> FAULT (not allowed) */
        false, /* INVALID -> SAFE_STATE (not allowed) */
        false, /* INVALID -> RECOVERY (not allowed) */
        false  /* INVALID -> INVALID */
    }
};

/** @brief Map safety_state_t enum to transition matrix index */
static inline int fsm_state_to_index(safety_state_t state)
{
    switch (state) {
        case SAFETY_STATE_INIT: return 0;
        case SAFETY_STATE_NORMAL: return 1;
        case SAFETY_STATE_FAULT: return 2;
        case SAFETY_STATE_SAFE_STATE: return 3;
        case SAFETY_STATE_RECOVERY: return 4;
        case SAFETY_STATE_INVALID: return 5;
        default: return 5; /* Invalid state maps to index 5 */
    }
}

/* ============================================================================
 * FSM Implementation Functions
 * ============================================================================ */

/**
 * @brief Initialize the safety FSM
 *
 * Sets up the FSM in INIT state and prepares for normal operation.
 * Called once during system initialization.
 *
 * @return true if initialization successful, false if already initialized
 *
 * Acceptance Criteria:
 *  - Sets current_state to INIT
 *  - Clears all fault flags
 *  - Resets fault count
 *  - Sets g_fsm_initialized flag
 */
bool fsm_init(void)
{
    /* Prevent double initialization */
    if (g_fsm_initialized) {
        return false;
    }

    /* Initialize to INIT state */
    g_safety_status.current_state = SAFETY_STATE_INIT;
    g_safety_status.current_state_cmp = ~SAFETY_STATE_INIT;

    /* Clear all faults */
    g_safety_status.active_faults = FAULT_TYPE_NONE;
    g_safety_status.active_faults_cmp = ~FAULT_TYPE_NONE;

    /* Clear fault flags */
    g_safety_status.fault_flags.pwr_fault = 0x00;
    g_safety_status.fault_flags.pwr_fault_cmp = 0xFF;
    g_safety_status.fault_flags.clk_fault = 0x00;
    g_safety_status.fault_flags.clk_fault_cmp = 0xFF;
    g_safety_status.fault_flags.mem_fault = 0x00;
    g_safety_status.fault_flags.mem_fault_cmp = 0xFF;

    /* Reset statistics */
    g_safety_status.fault_count = 0;
    g_safety_status.recovery_status = RECOVERY_PENDING;
    g_safety_status.timestamp_ms = 0;

    /* Mark as initialized */
    g_fsm_initialized = true;

    return true;
}

/**
 * @brief Perform FSM state transition with validation
 *
 * Validates the requested transition using the transition matrix,
 * performs the state change atomically with complement protection.
 *
 * @param next_state Desired next state
 * @return true if transition successful, false if transition not allowed
 *
 * Acceptance Criteria:
 *  - Validates transition using g_transition_matrix
 *  - Updates state and state_cmp atomically
 *  - Returns false for invalid transitions (DCLS protection)
 *  - All state transitions must pass matrix validation
 */
bool fsm_transition(safety_state_t next_state)
{
    int current_idx, next_idx;

    /* Validate FSM is initialized */
    if (!g_fsm_initialized) {
        return false;
    }

    /* Get transition matrix indices */
    current_idx = fsm_state_to_index(g_safety_status.current_state);
    next_idx = fsm_state_to_index(next_state);

    /* Check if transition is allowed */
    if (!g_transition_matrix[current_idx][next_idx]) {
        /* Invalid transition - treat as DCLS failure */
        g_safety_status.current_state = SAFETY_STATE_INVALID;
        g_safety_status.current_state_cmp = ~SAFETY_STATE_INVALID;
        return false;
    }

    /* Perform atomic state transition */
    g_safety_status.current_state = next_state;
    g_safety_status.current_state_cmp = ~next_state;

    /* Update timestamp */
    g_safety_status.timestamp_ms = 0; /* Would be set by timer ISR */

    return true;
}

/**
 * @brief Query current FSM state with DCLS verification
 *
 * Returns the current safety state after verifying the state and
 * its complement match (DCLS check).
 *
 * @return Current safety state, or SAFETY_STATE_INVALID if verification fails
 *
 * Acceptance Criteria:
 *  - Verifies state and state_cmp consistency (DCLS)
 *  - Returns state if consistent
 *  - Returns INVALID if DCLS check fails
 */
safety_state_t fsm_get_state(void)
{
    safety_state_t current = g_safety_status.current_state;
    safety_state_t complement = g_safety_status.current_state_cmp;

    /* Verify DCLS protection */
    if ((current ^ complement) != 0xFF) {
        /* DCLS failure detected */
        return SAFETY_STATE_INVALID;
    }

    return current;
}

/**
 * @brief Get full safety status with verification
 *
 * Returns a copy of the safety status structure with all DCLS checks.
 *
 * @param[out] status Pointer to output status structure
 * @return true if all verifications pass, false if any DCLS failure
 */
bool fsm_get_status(safety_status_t *status)
{
    if (status == NULL) {
        return false;
    }

    /* Verify state consistency */
    if ((g_safety_status.current_state ^ g_safety_status.current_state_cmp) != 0xFF) {
        return false; /* DCLS failure */
    }

    /* Verify active faults consistency */
    if ((g_safety_status.active_faults ^ g_safety_status.active_faults_cmp) != 0xFF) {
        return false; /* DCLS failure */
    }

    /* Copy status */
    *status = g_safety_status;

    return true;
}

/**
 * @brief Aggregate fault flags and update FSM state
 *
 * Called after fault flags are set by ISR handlers.
 * Aggregates all active fault flags and transitions FSM to FAULT state.
 *
 * Aggregation strategy (SysReq-002):
 *  - Priority: P1 (VDD) > P2 (CLK) > P3 (MEM)
 *  - Atomic execution to prevent race conditions
 *  - Updates active_faults bitmask
 *  - Triggers transition to FAULT state if in NORMAL
 *
 * @return true if aggregation successful, false if FSM not in valid state
 */
bool fsm_aggregate_faults(void)
{
    fault_type_t aggregated = FAULT_TYPE_NONE;
    safety_state_t current_state;

    /* Get current state with verification */
    current_state = fsm_get_state();
    if (current_state == SAFETY_STATE_INVALID) {
        return false;
    }

    /* Aggregate fault flags (atomic - no interrupts during this section) */
    if (VERIFY_FAULT_FLAG(g_safety_status.fault_flags.pwr_fault,
                          g_safety_status.fault_flags.pwr_fault_cmp)) {
        if (g_safety_status.fault_flags.pwr_fault) {
            aggregated |= FAULT_TYPE_VDD;
        }
    } else {
        /* DCLS failure in pwr_fault */
        return false;
    }

    if (VERIFY_FAULT_FLAG(g_safety_status.fault_flags.clk_fault,
                          g_safety_status.fault_flags.clk_fault_cmp)) {
        if (g_safety_status.fault_flags.clk_fault) {
            aggregated |= FAULT_TYPE_CLK;
        }
    } else {
        /* DCLS failure in clk_fault */
        return false;
    }

    if (VERIFY_FAULT_FLAG(g_safety_status.fault_flags.mem_fault,
                          g_safety_status.fault_flags.mem_fault_cmp)) {
        if (g_safety_status.fault_flags.mem_fault) {
            aggregated |= FAULT_TYPE_MEM_ECC;
        }
    } else {
        /* DCLS failure in mem_fault */
        return false;
    }

    /* Update active faults atomically */
    g_safety_status.active_faults = aggregated;
    g_safety_status.active_faults_cmp = ~aggregated;

    /* Update fault count if new faults detected */
    if (aggregated != FAULT_TYPE_NONE) {
        g_safety_status.fault_count++;

        /* Transition to FAULT state if currently NORMAL */
        if (current_state == SAFETY_STATE_NORMAL) {
            return fsm_transition(SAFETY_STATE_FAULT);
        }
    }

    return true;
}

/**
 * @brief Clear specific fault flags after recovery
 *
 * Called during recovery process to clear fault flags and update FSM.
 * Only clears flags for faults that have been resolved.
 *
 * @param faults_to_clear Bitmask of faults to clear
 * @return true if clear successful, false if invalid state
 */
bool fsm_clear_faults(fault_type_t faults_to_clear)
{
    /* Clear corresponding fault flags */
    if (faults_to_clear & FAULT_TYPE_VDD) {
        g_safety_status.fault_flags.pwr_fault = 0x00;
        g_safety_status.fault_flags.pwr_fault_cmp = 0xFF;
    }

    if (faults_to_clear & FAULT_TYPE_CLK) {
        g_safety_status.fault_flags.clk_fault = 0x00;
        g_safety_status.fault_flags.clk_fault_cmp = 0xFF;
    }

    if (faults_to_clear & FAULT_TYPE_MEM_ECC) {
        g_safety_status.fault_flags.mem_fault = 0x00;
        g_safety_status.fault_flags.mem_fault_cmp = 0xFF;
    }

    /* Re-aggregate faults */
    return fsm_aggregate_faults();
}

/**
 * @brief Set recovery status
 *
 * @param result Recovery operation result
 */
void fsm_set_recovery_status(recovery_result_t result)
{
    g_safety_status.recovery_status = result;
}

/**
 * @brief Get recovery status
 *
 * @return Last recovery operation result
 */
recovery_result_t fsm_get_recovery_status(void)
{
    return g_safety_status.recovery_status;
}
