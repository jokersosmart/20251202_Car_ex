# Traceability Matrix Template

## Feature Traceability Matrix

**Feature ID**: [XXX]  
**Feature Name**: [Feature name]  
**Created**: [Date]  
**Last Updated**: [Date]  
**Status**: [Planning/Development/Review/Complete]  
**Owner**: [Engineer name]

---

## Forward Traceability Matrix (Requirements → Implementation)

This matrix shows that every requirement has been implemented and tested.

| SG ID | FSR ID | SYS-REQ ID | TSR-HW ID | TSR-SW ID | RTL File | C File | HW Test | SW Test | Verified | Comments |
|-------|--------|-----------|----------|----------|----------|--------|---------|---------|----------|----------|
| SG-001-01 | FSR-001-01 | SYS-REQ-001-001 | TSR-HW-001-001 | TSR-SW-001-001 | power_detector.v | power_monitor.c | TC-HW-001-001 | TC-SW-001-001 | ✓ | Power detection: <1ms latency |
| SG-001-01 | FSR-001-02 | SYS-REQ-001-002 | TSR-HW-001-002 | TSR-SW-001-002 | capacitor_test.v | emergency_backup.c | TC-HW-001-002 | TC-SW-001-002 | ✓ | Backup power: 50ms hold-up |

---

## Backward Traceability Matrix (Implementation → Requirements)

This matrix shows that every piece of code and every test is traced back to a requirement.

| RTL/C File | Function/Module | Lines | Test Case | TSR-HW/SW ID | SYS-REQ ID | FSR ID | Justified |
|------------|-----------------|-------|-----------|----------|-----------|--------|-----------|
| power_detector.v | power_sense_logic | 45-67 | TC-HW-001-001 | TSR-HW-001-001 | SYS-REQ-001-001 | FSR-001-01 | ✓ |
| power_monitor.c | poll_pwr_status() | 120-135 | TC-SW-001-001 | TSR-SW-001-001 | SYS-REQ-001-001 | FSR-001-01 | ✓ |
| crc_check.v | crc_polynomial | 12-18 | **ORPHAN** | **NONE** | **NONE** | **NONE** | ❌ Need traceability |

---

## Test Coverage Matrix

| Requirement ID | Test Case ID | Test Type | Status | Coverage % | Pass/Fail | Notes |
|---|---|---|---|---|---|---|
| TSR-HW-001-001 | TC-HW-001-001 | Unit | ✓ | 100% code | ✓ PASS | All paths verified |
| TSR-HW-001-001 | TC-HW-001-002 | Integration | ✓ | 100% func | ✓ PASS | Latency: 850ns < 1ms |
| TSR-SW-001-001 | TC-SW-001-001 | Unit | ✓ | 100% stmt, 100% branch | ✓ PASS | Coverage tools confirmed |
| TSR-SW-001-001 | TC-SW-001-002 | Integration | ✓ | All scenarios | ✓ PASS | Real-time constraints met |

---

## Verification Status by Requirement

| Requirement | Design | Implemented | Unit Test | Integration | System Test | Status |
|---|---|---|---|---|---|---|
| SG-001-01 | ✓ | ✓ | ✓ | ✓ | ✓ | **VERIFIED** |
| FSR-001-01 | ✓ | ✓ | ✓ | ✓ | ✓ | **VERIFIED** |
| SYS-REQ-001-001 | ✓ | ✓ | ✓ | ✓ | ⏳ | In System Test |
| TSR-HW-001-001 | ✓ | ✓ | ✓ | ✓ | TBD | Ready for SYS Test |
| TSR-SW-001-001 | ✓ | ✓ | ✓ | ✓ | TBD | Ready for SYS Test |

---

## Change Impact Analysis

### When Requirements Change

**Changed Requirement**: SYS-REQ-001-001  
**Change Type**: Latency requirement: 1ms → 500µs  
**Date**: 2025-12-15  
**Initiator**: Safety Manager

| Affected Item | Current Status | Required Action | Owner | Due Date | Status |
|---|---|---|---|---|---|
| TSR-HW-001-001 | Approved | Re-verify timing | HW Lead | 2025-12-20 | ⏳ |
| power_detector.v | RTL v2.1 | Optimize logic | HW Engr | 2025-12-18 | 🟢 |
| TC-HW-001-001 | v1.0 | Update latency check | Test Engr | 2025-12-20 | ⏳ |
| design-review.md | Approved | Reschedule review | Lead | 2025-12-17 | ⏳ |

**Sign-off**: _____________________ Date: _______

---

### When Design Changes

**Changed Component**: power_detector.v  
**Change Summary**: Added redundant sensing path for fault tolerance  
**Date**: 2025-12-14  

| Affected Item | Action | Status |
|---|---|---|
| TSR-HW-001-001 (redundancy) | Verify requirements satisfied | ✓ |
| TC-HW-001-001 | Add redundancy test scenarios | ✓ |
| Traceability Matrix | No impact | ✓ |
| FMEA | Update mitigation assessment | ⏳ |

---

### When Implementation Changes

**Changed File**: power_monitor.c (poll_pwr_status function)  
**Change Summary**: Improved polling frequency from 50Hz to 100Hz  
**Date**: 2025-12-13  

| Affected Item | Action | Status |
|---|---|---|
| TC-SW-001-001 | Re-run unit tests (higher frequency) | ✓ |
| TC-SW-001-002 | Integration test with new frequency | ✓ |
| TSR-SW-001-001 | Verify timing still satisfied | ✓ |
| Performance metrics | Update baseline | ✓ |

---

## Coverage Gap Analysis

### Uncovered Requirements

| Requirement ID | Issue | Root Cause | Remediation | Owner | Target Date |
|---|---|---|---|---|---|
| TSR-SW-002-001 | No error case test | Test not written | Add error injection test | Test Lead | 2025-12-20 |
| TSR-HW-003-001 | Branch coverage 89% | Timeout path not hit | Add stress test | HW Tester | 2025-12-18 |

### Orphan Code (Not Traced)

| File | Lines | Function | Issue | Action | Owner |
|---|---|---|---|---|---|
| utility.c | 234-245 | debug_print() | Legacy debug code | Remove or trace to requirement | Dev Lead |
| test_helper.v | 50-60 | unused_monitor | Debug module | Retire or create requirement | Test Lead |

---

## Traceability Metrics

| Metric | Target | Actual | Status | Notes |
|---|---|---|---|---|
| Requirements Coverage | 100% | 98% | ⚠️ | 2 requirements not yet implemented |
| Code Traceability | 100% | 96% | ⚠️ | 4 helper functions not traced |
| Test Coverage | 100% | 100% | ✓ | All requirements have test cases |
| Design Completeness | 100% | 100% | ✓ | All TSRs have detailed design |
| Verification Completion | 100% | 92% | ⏳ | System test phase in progress |

---

## Approval Chain

The traceability matrix must be reviewed and approved:

1. **Technical Lead Review**: _____________________ Date: _______
2. **Quality Manager Review**: _____________________ Date: _______
3. **Safety Manager Review**: _____________________ Date: _______
4. **Program Manager Approval**: _____________________ Date: _______

---

## Version History

| Version | Date | Changes | Approved By |
|---------|------|---------|------------|
| 1.0 | 2025-12-02 | Initial traceability matrix | Lead |
| 1.1 | 2025-12-10 | Added change impact analysis | Lead |
| 1.2 | 2025-12-15 | Requirement latency change | Safety Mgr |

---

## Usage Notes

- Update this matrix as requirements, design, code, and tests evolve
- Run automated scripts monthly to identify gaps
- Use for phase gate reviews and compliance audits
- Archive versions at major baselines for historical reference
- Ensure 100% coverage before system-level testing
