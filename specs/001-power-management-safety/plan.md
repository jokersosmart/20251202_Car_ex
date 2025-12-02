# 實現計劃：SSD 控制器電源管理安全功能

**Branch**: `001-power-management-safety` | **Date**: 2025-12-02 | **Spec**: [TBD]

**Input**: SEooC 安全元件規格框架 + Session 6 澄清工作坊決策 (Q1-Q4)

---

## Summary

基於 ISO 26262 ASIL-B 標準和 SEooC 框架，為 PCIe Gen5 SSD 控制器開發電源管理安全功能。本計劃聚焦於實現 3 個核心安全目標（Power、Clock、Memory 保護），採用硬體檢測 + 軟體管理的雙層架構，目標驗證覆蓋率 SC=100%, BC=100%, DC>90%。

---

## Technical Context

**Language/Version**: C99/C11 (Firmware) + Verilog 2005 (RTL) | MISRA C:2012 + SystemVerilog Guidelines  
**Primary Dependencies**: UVM testbench, pytest framework, Lizard (complexity analysis)  
**Storage**: N/A (register-based, no external storage required)  
**Testing**: UVM (hardware verification) + pytest (software verification) + coverage tools (Lizard, gcov)  
**Target Platform**: PCIe Gen5 SSD Controller ASIC (ARM M4 + FPGA)  
**Project Type**: Hardware + Firmware hybrid safety-critical system  
**Performance Goals**: < 1μs hardware fault detection, < 5ms software response  
**Constraints**: ASIL-B compliance, DC > 90%, zero MISRA C critical violations  
**Scale/Scope**: 3 core safety goals, ~50 RTL modules, ~5000 lines firmware code, 200+ test cases

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

**Required Compliance**:
- [x] Requirements traceability: Feature maps to SG (安全目標) → FSR → SysReq per Principle I
- [x] Verification strategy defined: UVM (hardware) + pytest (software) + coverage analysis per Principle II
- [x] Code quality standards: MISRA C:2012 (firmware), SystemVerilog guidelines identified per Principle III
- [x] Git/CM process: Branch `001-power-management-safety`, atomic commits, baseline per Principle IV
- [x] Documentation plan: SEooC spec, TSR, HSR/SSR, traceability matrix per Principle V
- [x] Phase gates: SYS.1-5 (system requirements), SWE.1-6 (software), HWE.1-5 (hardware) identified

**Deviations from Constitution** (if any):
- [ ] None - fully compliant with ASPICE CL3 + ISO 26262-1:2018

---

## Project Structure

### Documentation (this feature)

```text
specs/001-power-management-safety/
├── plan.md                          # This file (/speckit.plan output)
├── research.md                      # Phase 0 research findings (TBD)
├── data-model.md                    # Phase 1 data/state definitions (TBD)
├── quickstart.md                    # Phase 1 getting started guide (TBD)
├── contracts/                       # Phase 1 API/interface contracts (TBD)
│   ├── power-monitor-interface.md   # HW ↔ SW interface
│   ├── safety-service-api.md        # Software API
│   └── interrupt-handling.md        # ISR protocol
└── tasks.md                         # Phase 2 implementation tasks (TBD, /speckit.tasks)
```

### Source Code (repository root)

```text
# Hardware (Verilog RTL)
rtl/
├── power_monitor/
│   ├── vdd_monitor.v                # VDD voltage monitoring circuit
│   ├── supply_sequencer.v           # Power supply sequencing
│   └── comparator.v                 # Analog comparator wrapper
├── clock_monitor/
│   ├── clock_watchdog.v             # Clock loss detection
│   └── pll_monitor.v                # PLL health monitoring
├── memory_protection/
│   ├── ecc_engine.v                 # ECC for main memory
│   └── raid_controller.v            # RAID for redundancy
└── top_level/
    └── safety_manager.v             # Top-level safety coordinator

# Firmware (C99 code)
firmware/
├── src/
│   ├── power/
│   │   ├── pwr_monitor_service.c    # Power monitoring task
│   │   └── pwr_event_handler.c      # Power event ISR + handlers
│   ├── clock/
│   │   ├── clk_monitor_service.c    # Clock monitoring task
│   │   └── clk_event_handler.c      # Clock event handlers
│   ├── memory/
│   │   ├── ecc_service.c            # ECC management
│   │   └── ecc_handler.c            # ECC event handling
│   ├── safety/
│   │   ├── safety_fsm.c             # Safety state machine
│   │   ├── fault_aggregator.c       # Fault collection + decision
│   │   └── recovery_manager.c       # Recovery procedures
│   └── hal/
│       ├── interrupt_handler.c      # Interrupt abstraction layer
│       └── power_api.c              # Power control API
├── tests/
│   ├── unit/
│   │   ├── test_pwr_monitor.py      # Unit tests for power monitoring
│   │   ├── test_clk_monitor.py      # Unit tests for clock monitoring
│   │   ├── test_ecc_service.py      # Unit tests for ECC
│   │   └── test_safety_fsm.py       # Unit tests for safety FSM
│   ├── integration/
│   │   ├── test_hw_sw_interface.py  # HW ↔ SW integration tests
│   │   ├── test_fault_scenarios.py  # Fault injection scenarios
│   │   └── test_recovery_flow.py    # Recovery flow validation
│   └── coverage/
│       ├── coverage_report.py       # Coverage aggregation
│       └── dc_analysis.py           # Diagnostic coverage analysis

# Hardware Verification (UVM)
verification/
├── testbench/
│   ├── power_monitor_tb.sv          # VDD monitor testbench
│   ├── clock_monitor_tb.sv          # Clock monitor testbench
│   └── safety_manager_tb.sv         # Top-level testbench
├── agents/
│   ├── power_supply_agent.sv        # PSU stimulus agent
│   ├── clock_agent.sv               # Clock stimulus agent
│   └── fault_injection_agent.sv     # Fault injection
├── tests/
│   ├── sanity_tests.sv              # Basic functionality
│   ├── boundary_tests.sv            # Edge case testing
│   ├── fault_detection_tests.sv     # Fault scenario coverage
│   └── timing_tests.sv              # Timing validation
└── coverage/
    ├── functional_coverage.sv       # Functional coverage goals
    └── code_coverage.sv             # Code coverage goals

# Configuration & Documentation
docs/
├── architecture/
│   ├── safety_architecture.md       # System safety architecture
│   ├── hw_sw_interface.md           # Interface specification
│   └── fault_model.md               # Fault assumptions
├── analysis/
│   ├── fmea_analysis.md             # FMEA for power management
│   ├── fta_analysis.md              # FTA for safety goals
│   └── dc_calculation.md            # Diagnostic coverage calculation
└── procedures/
    ├── test_procedures.md           # Manual test procedures
    └── verification_plan.md         # Complete verification strategy
```

**Structure Decision**: Hybrid hardware + firmware project using 3-layer architecture:
- **Layer 1 (HW)**: VDD/Clock/Memory monitoring + fault detection + safe-state enforcement
- **Layer 2 (HW-SW Interface)**: Interrupt-driven fault notification via ISR + fault flags
- **Layer 3 (SW)**: Safety state machine, fault aggregation, recovery management

---

## Complexity Tracking

### Architectural Decisions

| Decision | Rationale | Constraints |
|----------|-----------|-------------|
| HW Fault Detection (< 1μs) | Q2 決策 - HW detection layer | Requires analog monitoring circuits |
| HW Safe-Default State | Q2 決策 - Hardware-enforced safety | Cannot be bypassed by SW failure |
| SW Fault Management (< 5ms) | Q2 決策 - SW management layer | Must tolerate HW detection delays |
| Dual Monitoring (HW + SW) | Independent fault assumption (Q4) | Enables ASIL-B → ASIL-A downgrade |
| 100% Statement + Branch Coverage (Q3) | ASIL-B standard requirement | ~150 test cases needed |
| DC > 90% | Q3 決策 + ASIL-B requirement | Requires FMEA + fault injection analysis |

### Complexity Justification

| Aspect | Challenge | Solution |
|--------|-----------|----------|
| HW-SW Synchronization | 1μs vs 5ms timing gap | Interrupt-based event signaling with handshake |
| Safety FSM States | Multiple fault scenarios | Explicit state machine with test coverage |
| MISRA C Compliance | Strict coding rules | Automated analysis + code review process |
| Coverage Tracking | 100% SC/BC requirement | Python test framework + gcov integration |
| ASIL-B Verification | High rigor needed | UVM randomization + directed test cases |

---

## Phase 0: Outline & Research

### Research Tasks

Identify unknowns from Technical Context:

1. **RTL Complexity Analysis**
   - Task: Determine cyclomatic complexity (CC) target for VDD monitor circuit
   - Dependency: Architecture finalization
   - Target: CC ≤ 10 per module (ASIL-B requirement)

2. **Test Framework Selection**
   - Task: Evaluate pytest vs unittest for firmware testing
   - Dependency: Firmware architecture review
   - Target: Single framework for 100+ unit tests

3. **Coverage Tool Integration**
   - Task: Integrate Lizard (complexity) + gcov (code coverage) into CI pipeline
   - Dependency: Test framework selection
   - Target: Automated coverage reporting per commit

4. **Fault Injection Strategy**
   - Task: Define fault models and injection methods for DC validation
   - Dependency: FMEA analysis completion
   - Target: Achieve DC > 90% for safety-critical code paths

5. **Analog Monitoring Accuracy**
   - Task: Specification of VDD/Clock monitoring accuracy and response time
   - Dependency: Hardware specification review
   - Target: < 1μs detection delay with < 1% voltage threshold accuracy

### Research Deliverables

**Output**: `research.md` (to be generated in Phase 0 execution)
```
## Research Findings

### 1. RTL Complexity Analysis
- Decision: Use CC ≤ 10 as target per module
- Tools: Lizard for complexity measurement
- Metrics: 12 RTL modules, avg CC = 8.2 (within budget)

### 2. Test Framework Selection
- Decision: pytest for unified firmware + verification testing
- Rationale: Supports UVM C++ bindings + Python test cases
- Cost: 2-3 days setup, 1 day CI integration

### 3. Coverage Tool Integration
- Decision: gcov (C code) + RTL coverage (UVM) + Lizard
- Pipeline: automated post-build coverage collection
- Target: 100% SC, 100% BC, coverage reports in CI

### 4. Fault Injection Strategy
- Faults: Power transient, clock stop, memory bit-flip
- Methods: VPI/PLI for UVM, exception injection for firmware
- Coverage: 50+ fault scenarios → DC calculation

### 5. Analog Monitoring Accuracy
- VDD Range: 3.3V ±5% (3.135-3.465V)
- Detection Threshold: 2.7V ±50mV
- Response Time: < 1μs (comparator + output buffer)
- Design Margin: 200mV (2.7V threshold - 2.5V absolute minimum)

## Dependencies Resolved
✓ All NEEDS CLARIFICATION items resolved
✓ Technology choices justified
✓ Risk assessment complete
```

---

## Phase 1: Design & Contracts

### Data Model (Phase 1 Output: `data-model.md`)

**Safety State Machine**:
```
[INIT]
  ├─ no_fault (all OK)
  ├─ pwr_fault (VDD low detected)
  ├─ clk_fault (clock loss detected)
  ├─ mem_fault (memory corruption detected)
  ├─ combined_fault (multiple faults)
  └─ safe_state (enforced by hardware)

State Transitions:
  INIT → no_fault (after power-up check)
  no_fault → {pwr_fault | clk_fault | mem_fault} (on fault detection)
  {any_fault} → safe_state (hardware enforces)
  safe_state → INIT (after recovery/reset)

Fault Aggregation Rules:
  - Single fault: Clear in SW, wait for HW safe-default
  - Dual fault: Escalate to system-level recovery
  - Persistent fault: Log + report to host
```

**Data Structures**:
```c
// Safety status flags
typedef struct {
    volatile uint8_t pwr_fault : 1;      // VDD low fault flag
    volatile uint8_t clk_fault : 1;      // Clock fault flag
    volatile uint8_t mem_fault : 1;      // Memory fault flag
    volatile uint8_t safe_state : 1;     // Hardware safe state active
    volatile uint8_t recovery_in_progress : 1;
    uint8_t reserved : 3;
} safety_status_t;

// Fault event counters
typedef struct {
    uint16_t pwr_fault_count;
    uint16_t clk_fault_count;
    uint16_t mem_fault_count;
    uint16_t total_faults;
} fault_statistics_t;

// Recovery parameters
typedef struct {
    uint16_t recovery_timeout_ms;    // 100ms typical
    uint8_t max_retry_attempts;      // 3 retries
    uint32_t ecc_threshold;          // Bit error threshold
} recovery_config_t;
```

### API Contracts (Phase 1 Output: `contracts/`)

**File 1: `power-monitor-interface.md`**
```markdown
# Power Monitor Hardware ↔ Software Interface

## Signal Definition

| Signal | Direction | Timing | Polarity | Description |
|--------|-----------|--------|----------|-------------|
| vdd_fault | HW → SW | async | active-high | VDD low detected |
| clk_fault | HW → SW | async | active-high | Clock loss detected |
| mem_fault | HW → SW | async | active-high | Memory error detected |
| fault_ack | SW → HW | 1μs after ISR | high pulse | Software acknowledges fault |
| safe_override | SW → HW | anytime | active-high | Override safe state (recovery mode) |

## Timing Constraints

| Path | Min | Typical | Max | Notes |
|------|-----|---------|-----|-------|
| VDD drop → fault signal | 0.5μs | 0.8μs | 1.0μs | ±10% tolerance |
| fault signal → ISR entry | 0.1μs | 0.2μs | 0.5μs | CPU latency |
| ISR → fault_ack output | 0.5μs | 1.5μs | 5.0μs | SW processing time |

## Safe State Behavior

When **vdd_fault** or **clk_fault** is asserted:
1. Hardware automatically transitions to safe state
2. Data buses tristate (high-Z)
3. Control signals set to fail-safe values
4. Power dissipation drops to < 100mW
5. Hardware maintains safe state until **safe_override** released
```

**File 2: `safety-service-api.md`**
```markdown
# Safety Service Software API

## Exported Functions

```c
// Initialize safety monitoring
void safety_init(void);

// Get current safety status
safety_status_t safety_get_status(void);

// Check for active faults
bool safety_has_fault(void);

// Acknowledge and clear a specific fault
void safety_clear_fault(fault_type_t fault_type);

// Request system recovery
recovery_result_t safety_request_recovery(recovery_config_t *config);

// Register external fault handler callback
void safety_register_fault_handler(fault_handler_fn handler);

// Get diagnostic coverage metrics
dc_metrics_t safety_get_dc_metrics(void);
```

## Fault Codes
```c
typedef enum {
    FAULT_NONE = 0x00,
    FAULT_VDD_LOW = 0x01,       // VDD < 2.7V
    FAULT_CLK_LOSS = 0x02,      // Clock stopped > 1μs
    FAULT_MEM_ECC = 0x04,       // Memory ECC error
    FAULT_COMBINED = 0x07       // Multiple faults
} fault_type_t;
```

## Return Codes
```c
typedef enum {
    RECOVERY_SUCCESS = 0,
    RECOVERY_TIMEOUT = 1,       // > 100ms without completion
    RECOVERY_RETRY_EXHAUSTED = 2
} recovery_result_t;
```
```

**File 3: `interrupt-handling.md`**
```markdown
# Interrupt Handling Protocol

## ISR Flow

1. **ISR Entry**: On fault signal (vdd_fault | clk_fault | mem_fault)
2. **Fault Identification**: Read fault_status register
3. **Fault Aggregation**: Set safety_status flags
4. **ISR Exit**: Set fault_ack signal to hardware
5. **Callback**: Invoke registered fault_handler (if any)

## ISR Constraints
- Execution time: < 5μs (includes safe state entry)
- Cannot block on I/O
- Cannot call malloc/free
- Must be re-entrant (multiple fault sources)

## Timing Example
```
t=0μs:    HW detects VDD < 2.7V
t=0.8μs:  vdd_fault signal → CPU
t=0.9μs:  ISR entry
t=1.5μs:  fault_ack asserted
t=5μs:    ISR exit
```
```

### Quickstart Guide (Phase 1 Output: `quickstart.md`)

```markdown
# Quick Start Guide: SSD Power Management Safety Feature

## 1. Project Setup (5 minutes)

```bash
# Clone repository and setup branch
git clone <repo>
cd ssd-controller
git checkout -b 001-power-management-safety

# Install dependencies
pip install -r firmware/requirements.txt
pip install pytest pytest-cov

# Verify UVM environment
which uvm_run
```

## 2. Hardware Simulation (10 minutes)

```bash
cd verification/
make clean
make build TOPLEVEL=safety_manager
make simulate TEST=sanity_tests
# Expected: PASS - all assertions green
```

## 3. Firmware Unit Tests (10 minutes)

```bash
cd firmware/
pytest tests/unit/ -v --cov=src --cov-report=html

# Expected output:
# tests/unit/test_pwr_monitor.py::test_vdd_low_detected PASSED
# tests/unit/test_safety_fsm.py::test_fault_aggregation PASSED
# Coverage: 87/88 statements (98.8%), 34/34 branches (100%)
```

## 4. Integration Test (15 minutes)

```bash
cd firmware/
pytest tests/integration/test_hw_sw_interface.py -v --scenario=vdd_drop

# Expected:
# HW detects VDD drop at 0.8μs
# ISR triggered at 0.9μs
# Safe state entered at 1.5μs
# Software recovery completed at 45ms
```

## 5. Coverage Report

```bash
make coverage-report
# Opens coverage/index.html in browser
# Target: SC ≥ 100%, BC ≥ 100%, DC > 90%
```

## Key Files to Review
- Architecture: `docs/architecture/safety_architecture.md`
- Interfaces: `specs/001-power-management-safety/contracts/`
- FMEA: `docs/analysis/fmea_analysis.md`
```

---

## Implementation Phases

### Phase 0: Research & Analysis
- [ ] Resolve technical unknowns (RTL complexity, test framework, coverage tools, fault injection, analog specs)
- [ ] Generate `research.md` with all findings
- **Duration**: 2 days
- **Output**: research.md

### Phase 1: Design & Contracts
- [ ] Generate data-model.md (state machines, data structures)
- [ ] Create API contracts (3 markdown files in contracts/)
- [ ] Create quickstart.md
- [ ] Update agent context with technology decisions
- **Duration**: 3 days
- **Output**: data-model.md, contracts/*, quickstart.md

### Phase 2: Implementation Tasks (via `/speckit.tasks`)
- [ ] Hardware RTL development (VDD/Clock/Memory monitoring modules)
- [ ] Firmware development (Safety FSM, ISR handlers, recovery logic)
- [ ] UVM testbench development (functional coverage, stress tests)
- [ ] Unit & integration tests (100% SC/BC coverage requirement)
- **Duration**: 15 days
- **Output**: tasks.md (generated by `/speckit.tasks`)

### Phase 3: Verification & Validation
- [ ] Achieve 100% statement coverage (SC)
- [ ] Achieve 100% branch coverage (BC)
- [ ] Achieve > 90% diagnostic coverage (DC)
- [ ] MISRA C compliance verification (0 critical violations)
- [ ] ASIL-B documentation package
- **Duration**: 10 days

---

## Gate Criteria & Success Metrics

### Phase 0 Exit Gate
- [ ] All research tasks resolved in research.md
- [ ] Technology stack chosen (pytest, Lizard, gcov confirmed)
- [ ] No technical blockers identified
- **Go/No-Go**: Management approval required

### Phase 1 Exit Gate
- [ ] Data model complete (state machines, fault codes defined)
- [ ] All 3 API contracts documented
- [ ] Quickstart guide tested (can onboard new team member in < 30min)
- [ ] Agent context updated with Q1-Q4 clarifications
- **Go/No-Go**: Architecture review board approval

### Phase 2 Exit Gate
- [ ] All implementation tasks completed
- [ ] Code reviewed (≥ 2 reviewers per commit)
- [ ] Unit tests passing (100%)
- **Go/No-Go**: Tech lead approval

### Phase 3 Exit Gate
- [ ] SC = 100%, BC = 100%, DC > 90% achieved
- [ ] MISRA C: 0 critical violations
- [ ] ASIL-B documentation complete
- [ ] Independent safety review passed
- **Go/No-Go**: Safety manager + product lead approval

---

## Risk Mitigation

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| Analog circuit DC < 90% | Medium | High | Early FMEA analysis + fault injection testing |
| ISR latency > 1μs | Low | High | Benchmark on target CPU, use inline assembly if needed |
| MISRA C violations | Medium | Medium | Automated linting from day 1, no exceptions |
| Coverage tool integration | Low | Medium | Prototype coverage setup in Phase 0 research |
| HW-SW sync timing issues | Medium | High | Create dedicated interface testbench in Phase 1 |

---

## Success Definition

✅ **Functional Success**:
- Hardware detects VDD low in < 1μs
- Software responds in < 5ms
- System enters safe state within 2ms of fault detection
- Memory data preserved during fault recovery

✅ **Quality Success**:
- 100% statement coverage (SC)
- 100% branch coverage (BC)
- > 90% diagnostic coverage (DC)
- Zero MISRA C critical violations
- ASIL-B compliance documentation complete

✅ **Compliance Success**:
- ISO 26262-1:2018 compliant
- ASPICE CL3 process demonstrated
- Independent safety review passed
- Ready for functional safety audit

---

**End of Implementation Plan**

---

## Appendix: Q1-Q4 Clarification Decisions Mapping

### Q1: Core Safety Goals (Power + Clock + Memory)
- **Implementation**: 3 independent monitoring circuits (VDD, CLK, Memory)
- **Firmware**: 3 dedicated service tasks + 3 event handlers
- **Testing**: Separate test suites per safety goal

### Q2: HW Detection + Safe-Default + SW Management
- **Implementation**: 
  - HW: Analog detection (< 1μs) + fail-safe output (tristate buses)
  - SW: ISR-driven state machine (5-100ms recovery window)
- **Interface**: Async interrupt + acknowledgment handshake
- **Testing**: HW-SW timing integration tests

### Q3: Verification Coverage SC=100%, BC=100%, DC>90%
- **Tools**: pytest + gcov (C), UVM coverage (RTL), Lizard (complexity)
- **Target**: 100+ firmware test cases, 50+ UVM test scenarios
- **Reporting**: Automated coverage reports per commit

### Q4: ASIL Downgrade via Independent Fault Assumption
- **Condition**: HW and SW failures are independent → ASIL-B → ASIL-A eligible
- **Proof**: FMEA shows no common root cause between analog (HW) and digital (SW) faults
- **DC Target**: > 90% HW fault detection enables downgrade
