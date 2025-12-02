/**
 * @file fault_statistics.c
 * @brief ISO 26262 Fault Statistics and DC Calculation
 *
 * Tracks fault occurrences and calculates diagnostic coverage (DC)
 * per ISO 26262-1 Annex C.
 *
 * DC = (Faults detected) / (Faults detected + Faults not detected)
 *
 * Compliance:
 *  - ISO 26262-1:2018 Annex C (DC calculation)
 *  - ASPICE CL3 D.6.1 (Metrics and measurement)
 */

#include "safety_types.h"
#include <string.h>
#include <stdint.h>

/* ============================================================================
 * Global Statistics Variables
 * ============================================================================ */

/** @brief Global fault statistics (exported for monitoring) */
static volatile fault_statistics_t g_fault_stats = {
    .vdd_faults_detected = 0,
    .vdd_faults_undetected = 0,
    .clk_faults_detected = 0,
    .clk_faults_undetected = 0,
    .mem_faults_detected = 0,
    .mem_faults_undetected = 0,
    .recovery_successes = 0,
    .recovery_failures = 0,
    .uptime_ms = 0,
    .last_update_ms = 0
};

/** @brief Statistics update lock */
static volatile bool g_stats_locked = false;

/* ============================================================================
 * Statistics Update Functions
 * ============================================================================ */

/**
 * @brief Record a detected fault
 *
 * Called when a fault is successfully detected by a monitoring mechanism.
 * Updates fault type-specific counters.
 *
 * @param fault_type Type of detected fault (FAULT_TYPE_VDD, etc.)
 * @return true if update successful, false if locked
 */
bool fault_stats_record_detected(fault_type_t fault_type)
{
    if (g_stats_locked) {
        return false;
    }

    g_stats_locked = true;

    switch (fault_type) {
        case FAULT_TYPE_VDD:
            g_fault_stats.vdd_faults_detected++;
            break;
        case FAULT_TYPE_CLK:
            g_fault_stats.clk_faults_detected++;
            break;
        case FAULT_TYPE_MEM_ECC:
            g_fault_stats.mem_faults_detected++;
            break;
        default:
            g_stats_locked = false;
            return false;
    }

    g_fault_stats.last_update_ms = 0; /* Would be set by timer */
    g_stats_locked = false;

    return true;
}

/**
 * @brief Record an undetected fault (for DC calculation)
 *
 * In normal operation, undetected faults are unknown. However, during
 * safety analysis or fault injection testing, undetected faults may be
 * recorded to calculate realistic DC values.
 *
 * @param fault_type Type of undetected fault
 * @return true if update successful
 */
bool fault_stats_record_undetected(fault_type_t fault_type)
{
    if (g_stats_locked) {
        return false;
    }

    g_stats_locked = true;

    switch (fault_type) {
        case FAULT_TYPE_VDD:
            g_fault_stats.vdd_faults_undetected++;
            break;
        case FAULT_TYPE_CLK:
            g_fault_stats.clk_faults_undetected++;
            break;
        case FAULT_TYPE_MEM_ECC:
            g_fault_stats.mem_faults_undetected++;
            break;
        default:
            g_stats_locked = false;
            return false;
    }

    g_fault_stats.last_update_ms = 0;
    g_stats_locked = false;

    return true;
}

/**
 * @brief Record successful recovery
 *
 * Called when a fault recovery operation completes successfully.
 *
 * @return true if update successful
 */
bool fault_stats_record_recovery_success(void)
{
    if (g_stats_locked) {
        return false;
    }

    g_stats_locked = true;
    g_fault_stats.recovery_successes++;
    g_fault_stats.last_update_ms = 0;
    g_stats_locked = false;

    return true;
}

/**
 * @brief Record failed recovery
 *
 * Called when a fault recovery operation fails.
 *
 * @return true if update successful
 */
bool fault_stats_record_recovery_failure(void)
{
    if (g_stats_locked) {
        return false;
    }

    g_stats_locked = true;
    g_fault_stats.recovery_failures++;
    g_fault_stats.last_update_ms = 0;
    g_stats_locked = false;

    return true;
}

/* ============================================================================
 * DC (Diagnostic Coverage) Calculation Functions
 * ============================================================================ */

/**
 * @brief Calculate diagnostic coverage for a specific fault type
 *
 * DC = (Detected faults) / (Detected faults + Undetected faults)
 *
 * Per ISO 26262-1 Annex C, DC is expressed as a percentage:
 *  - DC >= 90% => Contributes positively to FMEA
 *  - DC >= 99% => High diagnostic effectiveness
 *
 * Acceptance Criteria:
 *  - Calculates DC as percentage (0-100)
 *  - Handles zero denominator (return 0%)
 *  - Uses integer arithmetic (no floating point for safety)
 *
 * @param fault_type Type of fault to calculate DC for
 * @param[out] dc_percent Pointer to store DC percentage (0-100)
 * @return true if calculation successful
 */
bool fault_stats_calculate_dc(fault_type_t fault_type, uint8_t *dc_percent)
{
    uint32_t detected = 0;
    uint32_t undetected = 0;
    uint32_t total;

    if (dc_percent == NULL) {
        return false;
    }

    /* Get fault type specific statistics */
    switch (fault_type) {
        case FAULT_TYPE_VDD:
            detected = g_fault_stats.vdd_faults_detected;
            undetected = g_fault_stats.vdd_faults_undetected;
            break;
        case FAULT_TYPE_CLK:
            detected = g_fault_stats.clk_faults_detected;
            undetected = g_fault_stats.clk_faults_undetected;
            break;
        case FAULT_TYPE_MEM_ECC:
            detected = g_fault_stats.mem_faults_detected;
            undetected = g_fault_stats.mem_faults_undetected;
            break;
        default:
            return false;
    }

    /* Calculate total potential faults */
    total = detected + undetected;

    /* Handle zero denominator */
    if (total == 0) {
        *dc_percent = 0; /* No faults observed */
        return true;
    }

    /* DC% = (Detected / Total) * 100 */
    /* Using integer arithmetic: (Detected * 100) / Total */
    *dc_percent = (uint8_t)((detected * 100) / total);

    /* Clamp to 100% */
    if (*dc_percent > 100) {
        *dc_percent = 100;
    }

    return true;
}

/**
 * @brief Calculate overall system DC
 *
 * Combined DC for all fault sources using weighted average:
 *  DC_system = (VDD_DC + CLK_DC + MEM_DC) / 3
 *
 * @param[out] dc_percent Pointer to store overall DC percentage
 * @return true if calculation successful
 */
bool fault_stats_calculate_overall_dc(uint8_t *dc_percent)
{
    uint8_t vdd_dc, clk_dc, mem_dc;
    uint16_t total_dc;

    if (dc_percent == NULL) {
        return false;
    }

    /* Calculate individual DCs */
    if (!fault_stats_calculate_dc(FAULT_TYPE_VDD, &vdd_dc) ||
        !fault_stats_calculate_dc(FAULT_TYPE_CLK, &clk_dc) ||
        !fault_stats_calculate_dc(FAULT_TYPE_MEM_ECC, &mem_dc)) {
        return false;
    }

    /* Calculate average DC */
    total_dc = (uint16_t)vdd_dc + clk_dc + mem_dc;
    *dc_percent = (uint8_t)(total_dc / 3);

    return true;
}

/**
 * @brief Get current fault statistics
 *
 * Returns a snapshot of current statistics.
 *
 * Acceptance Criteria:
 *  - Returns complete fault_statistics_t structure
 *  - Thread-safe with spin-lock protection
 *  - Includes all fault types and recovery outcomes
 *
 * @param[out] stats Pointer to output statistics structure
 * @return true if copy successful
 */
bool fault_stats_get_statistics(fault_statistics_t *stats)
{
    if (stats == NULL) {
        return false;
    }

    /* Wait for stats to be unlocked */
    while (g_stats_locked) {
        /* Spin-wait for stats to be available */
    }

    /* Copy statistics */
    stats->vdd_faults_detected = g_fault_stats.vdd_faults_detected;
    stats->vdd_faults_undetected = g_fault_stats.vdd_faults_undetected;
    stats->clk_faults_detected = g_fault_stats.clk_faults_detected;
    stats->clk_faults_undetected = g_fault_stats.clk_faults_undetected;
    stats->mem_faults_detected = g_fault_stats.mem_faults_detected;
    stats->mem_faults_undetected = g_fault_stats.mem_faults_undetected;
    stats->recovery_successes = g_fault_stats.recovery_successes;
    stats->recovery_failures = g_fault_stats.recovery_failures;
    stats->uptime_ms = g_fault_stats.uptime_ms;
    stats->last_update_ms = g_fault_stats.last_update_ms;

    return true;
}

/**
 * @brief Get recovery success rate
 *
 * Calculates the percentage of successful recoveries out of all
 * recovery attempts.
 *
 * @param[out] success_rate Pointer to store recovery success rate (0-100%)
 * @return true if calculation successful
 */
bool fault_stats_get_recovery_success_rate(uint8_t *success_rate)
{
    uint32_t total_attempts;

    if (success_rate == NULL) {
        return false;
    }

    total_attempts = g_fault_stats.recovery_successes +
                     g_fault_stats.recovery_failures;

    if (total_attempts == 0) {
        *success_rate = 0;
        return true;
    }

    *success_rate = (uint8_t)((g_fault_stats.recovery_successes * 100) /
                              total_attempts);

    if (*success_rate > 100) {
        *success_rate = 100;
    }

    return true;
}

/**
 * @brief Get total fault count
 *
 * @return Total number of faults detected across all types
 */
uint32_t fault_stats_get_total_faults(void)
{
    return g_fault_stats.vdd_faults_detected +
           g_fault_stats.clk_faults_detected +
           g_fault_stats.mem_faults_detected;
}

/**
 * @brief Reset all statistics
 *
 * Clears all counters and statistics. Typically called on system reset
 * or at the start of a new diagnostic session.
 *
 * @return true if reset successful
 */
bool fault_stats_reset(void)
{
    if (g_stats_locked) {
        return false;
    }

    g_stats_locked = true;

    memset((void *)&g_fault_stats, 0, sizeof(g_fault_stats));

    g_stats_locked = false;

    return true;
}

/**
 * @brief Update system uptime
 *
 * Called periodically by system timer to track total operating time.
 *
 * @param uptime_ms Current system uptime in milliseconds
 * @return true if update successful
 */
bool fault_stats_update_uptime(uint64_t uptime_ms)
{
    if (g_stats_locked) {
        return false;
    }

    g_stats_locked = true;
    g_fault_stats.uptime_ms = uptime_ms;
    g_stats_locked = false;

    return true;
}

/**
 * @brief Get fault rate (faults per hour)
 *
 * Calculates fault occurrence rate normalized to per-hour metric
 * for reliability analysis.
 *
 * @param[out] fph Pointer to store faults per hour
 * @return true if calculation successful
 */
bool fault_stats_get_fault_rate_per_hour(uint16_t *fph)
{
    uint32_t total_faults;
    uint64_t uptime_hours;

    if (fph == NULL) {
        return false;
    }

    total_faults = fault_stats_get_total_faults();

    /* Convert uptime from ms to hours */
    uptime_hours = g_fault_stats.uptime_ms / (1000 * 60 * 60);

    if (uptime_hours == 0) {
        *fph = 0;
        return true;
    }

    *fph = (uint16_t)(total_faults * 3600 / g_fault_stats.uptime_ms);

    return true;
}
