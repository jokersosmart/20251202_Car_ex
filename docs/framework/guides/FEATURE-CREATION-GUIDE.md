# Feature Creation Guide

**Purpose**: Step-by-step instructions for creating a new feature following ISO 26262 + ASPICE framework  
**Audience**: System Architects, Requirements Engineers, Hardware/Software Leads  
**Version**: 1.0.0

---

## Quick Start (5 minutes)

```powershell
# 1. Create a new feature directory
PS> cd .specify/scripts
PS> .\create-feature.ps1 -Name "Power Loss Protection" -ASIL "B" -Type "System"

# Output:
# Feature created: 001-power-loss-protection
# ✓ Directory structure created
# ✓ All templates populated
# ✓ Feature ID: 001
# ✓ Traceability matrix initialized
```

**Next Step**: Read "Detailed Walkthrough" section below for complete instructions.

---

## Detailed Walkthrough

### Phase 1: Feature Initialization (Day 1)

#### Step 1: Identify Feature Scope

Answer these questions:

**What safety hazard does this feature address?**
- Example: "Power loss during write operation could cause data corruption"

**What is the ASIL level?** (A=lowest, D=highest)
- Use HARA (Hazard Analysis and Risk Assessment) output
- SSD control features typically ASIL-B/C
- Safety-critical features (data integrity) → ASIL-B minimum

**What component does this belong to?**
- System: Multi-component interaction
- Hardware: Circuit, sensor, controller element
- Firmware: Algorithm, data structure, state machine

**Who are the stakeholders?**
- Technical lead, safety manager, test engineer, customer rep

#### Step 2: Generate Feature Structure

**Using the script** (recommended):

```powershell
.\create-feature.ps1 `
  -Name "Power Loss Protection" `
  -ASIL "B" `
  -Type "System" `
  -Owner "John Smith" `
  -Stakeholders "Jane Lead, Bob Safety, Alice Test"
```

**Manual approach** (if script unavailable):

1. Create directory: `specs/001-power-loss-protection/`
2. Copy templates from `docs/framework/templates/` into feature directory
3. Create subdirectories: `review-records/`
4. Initialize all template files with feature metadata

#### Step 3: Create Feature Overview

Edit `specs/001-power-loss-protection/spec.md`:

```markdown
# Feature 001: Power Loss Protection

**ASIL**: B  
**Type**: System (Hardware + Firmware)  
**Owner**: John Smith  
**Created**: 2025-12-16  
**Status**: Planning

## Executive Summary

The system must detect power loss during NAND write operations and safely 
abort the write to prevent data corruption. Upon detection, firmware must 
checkpoint current state and notify host of operation failure.

## Hazard Reference

From HARA analysis:
- **Hazard H-3.2**: Power loss during flash write → corrupted data block
- **Severity**: S3 (possible data loss)
- **Exposure**: E3 (driving conditions)
- **Controllability**: C2 (driver can mitigate by powering off cleanly)
- **ASIL**: B (per ISO 26262-3:2018)

## Business Driver

- Improve SSD reliability: Zero unplanned data loss
- Reduce customer support: Avoid warranty claims
- Competitive advantage: Exceeds industry reliability standards
```

---

### Phase 2: Requirements Analysis (Days 2-5)

#### Step 1: Establish Safety Goals

Edit `specs/001-power-loss-protection/requirements.md`:

```markdown
## Safety Goals

### SG-001-01: Prevent Data Corruption on Power Loss

**Description**: The system shall detect loss of main power supply during 
active NAND write operations and safely terminate the operation to prevent 
data corruption.

**Hazard Reference**: H-3.2 (Power loss during write)

**ASIL**: B

**Acceptance Criteria**:
- All data corruption scenarios from HARA addressed by this goal
- Functional Safety Requirements below implement this goal
- System qualification tests verify goal achievement
```

#### Step 2: Define Functional Safety Requirements

Continue in `requirements.md`:

```markdown
## Functional Safety Requirements (FSR)

### FSR-001-01: Power Loss Detection

**Description**: System shall detect loss of main power supply within 1 millisecond

**Type**: Detection

**ASIL**: B (inherited from SG-001-01)

**Rationale**: Fast detection enables safe write termination before data corruption occurs

**Acceptance Criteria**:
- Detection latency measured < 1 millisecond
- Detection method operates during all SSD power states
- False positive rate < 1 per million operations

### FSR-001-02: Safe Write Termination

**Description**: Upon power loss detection, system shall immediately terminate 
active write operations and preserve system state for recovery.

**Type**: Mitigation

**ASIL**: B

**Rationale**: Prevents partial writes that cause data corruption

**Acceptance Criteria**:
- Active NAND write command aborted within 500 microseconds
- In-flight data flushed or discarded (not partially committed)
- System state checkpointed to allow recovery after power restoration

### FSR-001-03: Host Notification

**Description**: Upon power loss recovery, system shall notify host of failed operations

**Type**: Recovery

**ASIL**: B

**Rationale**: Allows host to retry operations or notify user of power event

**Acceptance Criteria**:
- Power loss event logged with timestamp
- Host receives command completion status (error) for failed operations
```

#### Step 3: Derive System Requirements

Continue in `requirements.md`:

```markdown
## System Requirements (SYS-REQ)

### SYS-REQ-001-001: Power Supply Monitoring

**Derives From**: FSR-001-01

**Description**: System shall continuously monitor main power supply voltage 
and detect when it falls below operational threshold (3.0V for 3.3V supply).

**ASIL**: B

**Functional Scope**: 
- Monitors 3.3V main power rail
- Excludes backup/standby power monitoring
- Active during all SSD operational modes

**Timing**: Detection latency < 1ms

**Acceptance Criteria**:
- Threshold crossing detection verified in SYS test
- Latency measurement from voltage drop to interrupt signal < 1ms
- Works across process/temperature/voltage corners per silicon specs

### SYS-REQ-001-002: Write Command Abort

**Derives From**: FSR-001-02

**Description**: Upon power loss detection, all active NAND write commands 
shall be terminated and in-flight data discarded.

**ASIL**: B

**Acceptance Criteria**:
- NAND write command aborted within 500 microseconds of detection signal
- NAND data buffer cleared to prevent partial writes
- Microcontroller halts further write operations

### SYS-REQ-001-003: State Checkpointing

**Derives From**: FSR-001-02

**Description**: Critical system state shall be checkpointed to enable recovery 
after power loss.

**ASIL**: B

**Acceptance Criteria**:
- Critical state: current wear-leveling map, block management state, command queue
- Checkpointing completes within 5ms after write abort
- Checkpoint verified with CRC during next power-on
```

#### Step 4: Allocate to Technical Requirements

Continue in `requirements.md`:

```markdown
## Technical Safety Requirements - Hardware (TSR-HW)

### TSR-HW-001-001: Power Detector Circuit

**Derives From**: SYS-REQ-001-001

**Component**: Power Monitor

**Description**: Dedicated analog/digital circuit shall monitor 3.3V supply 
voltage and generate interrupt signal when voltage falls below 3.0V.

**Timing**: Voltage-to-interrupt latency < 1 millisecond

**Design Constraints**:
- Area: < 0.5 mm²
- Power: < 1 mW in operation
- Temperature range: -40°C to +85°C

**Safety Mechanisms**:
- Redundant voltage threshold comparison (hysteresis)
- Independent signal path to microcontroller
- Built-in self-test (BIST) for circuit verification

**RTL Files**: `rtl/power_monitor.v`

**Test Cases**: `TC-HW-001-001`, `TC-HW-001-002`

## Technical Safety Requirements - Software (TSR-SW)

### TSR-SW-001-001: Power Loss Interrupt Handler

**Derives From**: SYS-REQ-001-002

**Module**: Firmware Power Manager

**Description**: Interrupt service routine shall abort active NAND write 
and execute safe shutdown sequence.

**Timing**: Handler execution time < 500 microseconds

**Algorithm**:
1. Save current command pointer to backup RAM
2. Send abort command to NAND controller
3. Clear data buffers
4. Set power-loss flag
5. Enter ultra-low-power mode

**MISRA C:2012 Compliance**: Section 8.2 (automotive coding standard)

**Code Files**: `firmware/power_manager.c`

**Test Cases**: `TC-SW-001-001`, `TC-SW-001-002`
```

#### Step 5: Requirements Review

Create `review-records/requirements-review.md`:

```markdown
# Requirements Review Meeting

**Date**: 2025-12-18  
**Attendees**: John Smith (Owner), Jane Lead (Technical Lead), Bob Safety (Safety Manager)  
**Duration**: 1.5 hours

## Review Checklist

- [x] All requirements are clear and unambiguous
- [x] All requirements are verifiable and testable
- [x] All requirements trace to parent (FSR/SYS-REQ)
- [x] All requirements have acceptance criteria
- [x] ASIL levels correctly inherited
- [x] Safety goals address all hazards from HARA
- [x] No contradictions between requirements
- [x] Required documentation referenced
- [x] Schedule and resource estimates reasonable

## Issues Raised

**Issue 1**: Detection latency not specified for all voltage conditions  
**Resolution**: Added corner cases: process (TT/FF/SS), temperature (-40/+25/+85), voltage (3.0-3.6V)  
**Owner**: John Smith  
**Due**: 2025-12-19  

**Issue 2**: Recovery mechanism after power restoration unclear  
**Resolution**: Added FSR-001-03 for host notification  
**Owner**: John Smith  
**Due**: 2025-12-19  

## Sign-off

✓ **Approved** by Jane Lead (Technical Lead) - Date: 2025-12-18  
✓ **Approved** by Bob Safety (Safety Manager) - Date: 2025-12-18  

**Status**: SYS-REQ finalized and baselined
```

---

### Phase 3: Architecture and Detailed Design (Days 6-10)

#### Step 1: System Architecture

Create `specs/001-power-loss-protection/architecture.md`:

```markdown
# System Architecture

## Block Diagram

```
Main Power (3.3V)
  ├─→ Power Monitor Circuit (analog comparator)
  │     └─→ Interrupt Signal
  │           └─→ Microcontroller NVIC (Normal Vector Interrupt Controller)
  │                 └─→ Power Loss Interrupt Handler (firmware)
  │                       ├─→ NAND Controller (abort command)
  │                       └─→ Checkpoint to backup RAM

Secondary Power (Standby)
  └─→ Backup Power Supply (capacitor bank)
        └─→ Ultra-low-power mode (preserve state)
```

## Interface Specification

**Power Monitor → Microcontroller**:
- Signal: `pwr_loss_n` (active low interrupt)
- Timing: < 1ms propagation
- Voltage levels: 3.3V CMOS

**Microcontroller → NAND Controller**:
- Command: Write Abort
- Timing: < 500µs
- Protocol: Existing NVMe protocol

## Component Allocation

| Requirement | Hardware Component | Software Module |
|---|---|---|
| SYS-REQ-001-001 | Power Monitor (TSR-HW-001-001) | - |
| SYS-REQ-001-002 | NAND Controller | Interrupt Handler (TSR-SW-001-001) |
| SYS-REQ-001-003 | Backup RAM | Checkpoint Manager (TSR-SW-001-002) |
```

#### Step 2: Detailed Design

Create `specs/001-power-loss-protection/detailed-design.md`:

```markdown
# Detailed Design

## Power Monitor Circuit (Hardware)

**Design Overview**:
- Precision analog comparator monitors 3.3V rail
- Threshold: 3.0V ± 2% with hysteresis
- Output: 5ns propagation delay (typ)
- Ultra-low quiescent current: 50µA

**Schematic**: `rtl/power_monitor.v` lines 1-45

**Timing Analysis**:
- Voltage drop rate: 5V/ms (worst case)
- Detection threshold crossing: 0.2ms
- Comparator propagation: 20ns
- Signal routing: <500ns
- **Total**: <1ms ✓

## Interrupt Handler (Software)

**ISR Flow Chart**:
```
Power Loss Interrupt
  ├─ Save return address (auto)
  ├─ Disable interrupts
  ├─ Read current NAND state
  ├─ Send NAND abort command
  ├─ Clear write buffer
  ├─ Checkpoint state to backup RAM
  ├─ Set power-loss-flag
  └─ Enter ultra-low-power wait
```

**Timing Budget**:
- Save/restore: 10 cycles (100ns)
- Disable interrupts: 5 cycles (50ns)
- NAND abort: 200 cycles (2µs)
- Buffer clear: 100 cycles (1µs)
- Checkpoint: 350 cycles (3.5µs)
- **Total**: 665 cycles (6.65µs) < 500µs ✓

## State Checkpoint Format

**Backup RAM Layout** (192 bytes):

```c
typedef struct {
    uint32_t magic;           // 0x5A5A5A5A
    uint32_t wear_level_map[16];
    uint32_t block_state[32];
    uint16_t command_queue[8];
    uint32_t crc32;
} power_loss_checkpoint_t;
```

**CRC Verification**: CRC32-CCITT on boot to verify integrity
```

---

### Phase 4: Safety Analysis (Days 11-15)

#### Step 1: FMEA

Create `specs/001-power-loss-protection/fmea.md`:

```markdown
# Failure Mode and Effects Analysis

| ID | Failure Mode | Causes | Effects | S | O | D | RPN | Mitigation | Residual |
|----|---|---|---|---|---|---|---|---|---|
| FM-001 | Power detector fails | Component defect | Late/no detection | 10 | 2 | 8 | 160 | Redundant detector + BIST | 40 |
| FM-002 | Comparator drift | Temperature variation | Missed detection at corner | 9 | 2 | 7 | 126 | Precision trimming + monitoring | 36 |
| FM-003 | IRQ signal lost | Signal integrity | No handler execution | 10 | 1 | 9 | 90 | Watchdog timer backup | 30 |

**Mitigation Details**:

**FM-001**: Redundant Detector  
- Primary: Precision comparator  
- Secondary: Firmware-based voltage monitoring  
- Both must fail for undetected loss  

**FM-002**: Temperature Compensation  
- On-chip temperature sensor  
- Threshold adjusted per temperature  
- Calibration at manufacturing  

**FM-003**: Watchdog Backup  
- 1.5ms watchdog triggered on power loss  
- Forces safe shutdown if IRQ fails  
- Monitored as separate fault tree
```

#### Step 2: FTA

Create `specs/001-power-loss-protection/fta.md`:

```markdown
# Fault Tree Analysis

**Top Event**: Undetected power loss during write operation

## Fault Tree Structure

```
       Undetected Power Loss
              |
        ______+______
       |             |
   No Detection   Detection Failed
   from Circuit    to Execute
       |               |
  _____|______      ___|___
 |           |    |       |
Detector   IRQ   Handler  Write
Fails      Lost  Timeout  Not Aborted
```

## Minimal Cut Sets

**1st Order**:
- Detector IC failure → Undetected power loss
- Microcontroller IRQ path failure → No handler execution
- Handler timeout (shouldn't occur) → Write not aborted

**2nd Order** (Common Cause):
- Voltage rail glitch AND detector threshold miscalibration
- Temperature excursion AND comparator drift

## Quantitative Analysis

**Top Event Probability** (target): < 1e-7 per power-off event

| Component | Failure Rate | Calc | Probability |
|---|---|---|---|
| Detector (primary) | 100 FIT | 1e-7/hr | 8.76e-4/yr |
| Detector (redundant) | 100 FIT | 1e-7/hr | 8.76e-4/yr |
| Both fail simultaneously | (1e-7)² | | <1e-14/yr |
| IRQ path | 50 FIT | 5e-8/hr | 4.38e-4/yr |
| Watchdog backup | 50 FIT | 5e-8/hr | 4.38e-4/yr |

**Residual Risk**: 1e-13 per power-off (exceeds target) ✓
```

---

### Phase 5: Implementation Verification Plan (Days 16-20)

#### Step 1: Test Specifications

Create `specs/001-power-loss-protection/unit-test-spec.md`:

```markdown
# Unit Test Specification

## Hardware Unit Tests

### TC-HW-001-001: Power Detector Threshold

**Objective**: Verify power detector triggers at 3.0V threshold

**Test Setup**:
- Programmable power supply
- Oscilloscope for latency measurement
- Detector output connected to logic analyzer

**Test Steps**:
1. Set supply to 3.3V (nominal operation)
2. Gradually reduce voltage
3. Observe at what voltage interrupt triggers
4. Measure propagation delay

**Expected Results**:
- Trigger at 3.0V ± 2% across all corners
- Propagation delay < 1ms

**Acceptance**: Measured threshold within ± 2%, latency < 1ms

### TC-HW-001-002: Power Detector BIST

**Objective**: Verify built-in self-test functionality

**Test Steps**:
1. Trigger BIST during normal operation
2. Verify both detectors respond correctly
3. Check redundancy voting logic

**Acceptance**: BIST reports both detectors operational

## Software Unit Tests

### TC-SW-001-001: Interrupt Handler Execution

**Objective**: Verify power loss handler executes within timing budget

**Test Code**:
```c
void test_pwr_loss_handler() {
    // Setup
    nand_write_command(0x80);
    clear_power_loss_flag();
    
    // Trigger simulation
    uint32_t start_time = get_timer();
    simulate_power_loss_interrupt();
    uint32_t elapsed = get_timer() - start_time;
    
    // Verify
    assert(elapsed < 500);  // microseconds
    assert(is_nand_write_aborted());
    assert(is_checkpoint_valid());
}
```

**Coverage**: 100% statement, 100% branch

### TC-SW-001-002: Checkpoint Integrity

**Objective**: Verify state checkpoint can be recovered

**Test Code**:
```c
void test_checkpoint_recovery() {
    // Save reference state
    power_loss_checkpoint_t ref_state = get_current_state();
    
    // Simulate power loss
    simulate_power_loss_checkpoint();
    
    // Power back on
    power_on_reset();
    power_loss_checkpoint_t recovered = load_checkpoint();
    
    // Verify
    assert(recovered.crc32 == calculate_crc32(&recovered));
    assert_equal_state(&ref_state, &recovered);
}
```

**Coverage**: 100% statement, 100% branch
```

#### Step 2: Integration Test Specification

Create `specs/001-power-loss-protection/integration-test-spec.md`:

```markdown
# Integration Test Specification

## Hardware/Firmware Integration

### TC-INT-001-001: Power Loss Detection to Write Abort

**Objective**: Verify end-to-end power loss handling

**Test Setup**:
- SSD with power monitor and NAND controller
- Live NAND flash with data
- Power supply switchable between operation and test mode

**Test Scenario**:
1. Initiate NAND write to known block
2. After 50% of write command completes, simulate power loss
3. Power restored after 100ms
4. Verify write was aborted (data not written)

**Acceptance**:
- Write command fails (error status returned on recovery)
- Written data checksum different from expected
- No data corruption to adjacent blocks

### TC-INT-001-002: Backup Power Verification

**Objective**: Verify backup capacitors support state checkpoint

**Test**:
1. Monitor backup power voltage during power loss event
2. Measure available time window for checkpoint
3. Verify checkpoint completes before backup voltage collapses

**Acceptance**: Checkpoint completes with > 50% voltage margin
```

---

### Phase 6: Safety Analysis Documents

#### Step 1: Create FMEA, FTA, DFA (as shown above)

Then create summary: `specs/001-power-loss-protection/change-log.md`

```markdown
# Change Log

| Version | Date | Change | Reason | Approved |
|---------|------|--------|--------|----------|
| 1.0 | 2025-12-20 | Initial feature release | Feature complete | Jane Lead |
| 1.1 | 2025-12-25 | Latency requirement: 1ms → 500µs | Customer feedback | Bob Safety |
| 1.2 | 2026-01-05 | Added redundant detector | Risk assessment | Safety Mgr |
```

---

### Phase 7: Traceability Matrix

Create/Update `specs/001-power-loss-protection/traceability.md` using [TRACEABILITY-MATRIX-TEMPLATE.md](TRACEABILITY-MATRIX-TEMPLATE.md)

---

### Phase 8: Final Reviews and Approval

#### Code Review

Create `review-records/code-review.md`:

```markdown
# Code Review Meeting

**Date**: 2026-01-10  
**Reviewed Files**:
- firmware/power_manager.c
- rtl/power_monitor.v
- tests/test_power_manager.c

**Checklist**:
- [x] Coding standards (MISRA C for firmware, SystemVerilog for RTL)
- [x] Traceability tags present (@requirement, @test-case)
- [x] No violations of architectural patterns
- [x] Coverage metrics acceptable (100% statement, branch)
- [x] Error handling complete
- [x] No memory leaks (firmware)
- [x] Performance requirements met

**Issues**: None critical - minor comments addressed

**Approval**: ✓ John Developer (Peer), ✓ Lead Reviewer
```

#### Verification Review

Create `review-records/verification-review.md`:

```markdown
# Verification Review

**Date**: 2026-01-15

**Test Execution Summary**:
- Unit tests (HW): 15/15 PASS
- Unit tests (FW): 12/12 PASS
- Integration tests: 8/8 PASS
- System tests: 5/5 PASS

**Coverage Metrics**:
- Statement coverage: 100%
- Branch coverage: 100%
- Functional coverage: 100%

**Defects**: 0 critical, 0 major, 3 minor (all resolved)

**Sign-off**:
✓ Test Lead  
✓ Quality Manager  
✓ Safety Manager
```

---

## Automation Commands

### Create Feature

```powershell
.\create-feature.ps1 `
  -Name "Power Loss Protection" `
  -ASIL "B" `
  -Type "System" `
  -Owner "John Smith"
```

### Check Traceability

```powershell
.\check-traceability.ps1 -Feature "001-power-loss-protection"
# Output: Traceability report, identifies gaps
```

### Run Change Impact Analysis

```powershell
.\check-change-impact.ps1 `
  -File "firmware/power_manager.c" `
  -ChangeType "implementation"
# Output: Lists all affected requirements, design docs, tests
```

### Verify Coverage

```powershell
.\check-requirements-coverage.ps1 -Feature "001-power-loss-protection"
# Output: Coverage report, shows what's missing
```

---

## Best Practices

✅ **DO**:
- Start with hazard analysis (HARA) output
- Involve safety expert early
- Review requirements before design
- Maintain traceability continuously
- Automate traceability checks
- Document all decisions with rationale

❌ **DON'T**:
- Create design without requirements review
- Skip safety analysis (FMEA/FTA/DFA)
- Have orphan code without traceability
- Change requirements without impact analysis
- Skip final verification review
- Archive without version control

---

## Common Pitfalls and Solutions

| Pitfall | Problem | Solution |
|---------|---------|----------|
| Requirements too vague | "System shall be fast" | Use acceptance criteria: "< 1ms" |
| Incomplete allocation | TSR doesn't cover SYS-REQ | Review checklist: all SYS-REQ → TSR |
| Lost traceability | Code changes, tests not updated | Auto-trace extraction from source |
| Cascading changes | One requirement change affects 10 items | Change impact analysis script |
| No safety analysis | Unknown failure modes | FMEA/FTA/DFA required for ASIL-B |

---

## Next Steps After Feature Complete

1. ✓ Baseline feature in Git (tag: `001-v1.0`)
2. ✓ Archive all review records
3. ✓ Create lesson-learned notes
4. ✓ Begin planning dependent features
5. ✓ Start next feature using same process

**Questions?** Contact: Safety Manager, Technical Lead, or Process Owner
