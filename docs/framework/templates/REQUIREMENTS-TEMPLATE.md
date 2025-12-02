# Requirements Template

This template follows ISO 26262 and ASPICE requirements specification standards.

## Safety Goal Template (SG-XXX-YY)

A Safety Goal is a high-level statement of the intended functional safety that must be achieved.

### SG-001-01: [Safety Goal Title]

- **Description**: [Clear statement of the safety objective - what hazard is being addressed]
- **Hazard Reference**: [Link to HARA output - e.g., "Hazard #3.2"]
- **Rationale**: [Why this goal is necessary for safety]
- **Automotive Function**: [Which vehicle/system function this protects]
- **ASIL**: [B] (inherited from hazard analysis)
- **Acceptance Criteria**: [How we know this goal is met - must be objective]

---

## Functional Safety Requirement Template (FSR-XXX-YY)

A Functional Safety Requirement is a requirement that specifies a specific safety functionality that implements a Safety Goal.

### FSR-001-01: [FSR Title]

- **Description**: [Specific functional safety capability required - what must the system do]
- **Type**: [Detection/Prevention/Mitigation/Recovery]
- **Implements**: [Parent Safety Goal - e.g., "SG-001-01"]
- **ASIL**: [B] (inherited from parent goal)
- **Priority**: [Mandatory/Desired/Optional]
- **Rationale**: [Technical rationale for this functional requirement]
- **Functional Scope**: [Boundary of this function - what is included/excluded]
- **Timing**: [Timing constraints if applicable]
- **Acceptance Criteria**: [How we verify this requirement is met - measurable]
- **Verification Method**: [Test/Analysis/Inspection/Demonstration]
- **Derived Requirements**: [List of child system requirements - e.g., "SYS-REQ-001-001, SYS-REQ-001-002"]
- **Status**: [Draft/Approved/Implemented/Verified]

---

## System Requirement Template (SYS-REQ-XXX-YYY)

A System Requirement specifies what the system must do to implement functional safety requirements.

### SYS-REQ-001-001: [System Requirement Title]

- **Description**: [Clear, testable requirement statement]
- **Type**: [Functional/Performance/Interface/Constraint/Safety]
- **Derives From**: [Parent FSR - e.g., "FSR-001-01"]
- **ASIL**: [B] (inherited from FSR)
- **Priority**: [Mandatory/Desired/Optional]
- **Rationale**: [Why this system requirement is necessary]
- **Functional Scope**: [What this covers and boundaries]
- **Interfaces**: [System interfaces affected]
- **Constraints**: [Timing, power, resource constraints]
- **Acceptance Criteria**: [Objective, measurable pass/fail criteria]
- **Verification Method**: [Test/Analysis/Inspection/Demonstration]
- **Allocated Components**: [Hardware/Firmware components responsible - e.g., "Controller, Flash Manager"]
- **Technical Safety Requirements**:
  - Hardware: [TSR-HW-001-001]
  - Software: [TSR-SW-001-001]
- **Dependencies**: [Other requirements this depends on]
- **Status**: [Draft/Approved/Implemented/Verified]

---

## Technical Safety Requirement - Hardware Template (TSR-HW-XXX-YYY)

A Hardware Technical Safety Requirement specifies the hardware implementation to satisfy system requirements.

### TSR-HW-001-001: [Hardware TSR Title]

- **Description**: [Hardware-specific requirement - what must the hardware do]
- **Derives From**: [Parent system requirement - e.g., "SYS-REQ-001-001"]
- **ASIL**: [B] (inherited from parent)
- **Component**: [Specific hardware module - e.g., "Power Loss Detector", "Error Corrector"]
- **Type**: [Detection/Protection/Monitoring/Control]
- **Functional Specification**:
  - **Input Signals**: [Inputs to monitor/control]
  - **Output Signals**: [Outputs generated]
  - **State Transitions**: [State changes required]
  - **Timing**: [Latency, frequency, timing constraints]
- **Design Constraints**: [Area, power, temperature constraints]
- **Safety Mechanisms**: [Built-in safety features - redundancy, monitoring, fault injection]
- **Acceptance Criteria**: [Hardware behavior verification criteria]
- **Verification Method**: [Simulation/Formal Verification/Hardware Test/Analysis]
- **Test Cases**: [Reference to test cases - e.g., "TC-HW-001-001"]
- **RTL Implementation**: [Reference to RTL files - e.g., "rtl/power_monitor.v"]
- **Coverage Target**: [Code/Functional coverage goals - e.g., "100% toggle coverage"]
- **Dependencies**: [Other hardware requirements]
- **Status**: [Draft/Approved/Implemented/Verified]

---

## Technical Safety Requirement - Software Template (TSR-SW-XXX-YYY)

A Software Technical Safety Requirement specifies the software/firmware implementation.

### TSR-SW-001-001: [Software TSR Title]

- **Description**: [Software-specific requirement - what must the software do]
- **Derives From**: [Parent system requirement - e.g., "SYS-REQ-001-001"]
- **ASIL**: [B] (inherited from parent)
- **Module**: [Firmware module - e.g., "Wear Leveling Manager", "SMART Monitoring"]
- **Type**: [Algorithm/Data Processing/State Machine/Communication/Monitoring]
- **Functional Specification**:
  - **Inputs**: [Data inputs]
  - **Outputs**: [Results/actions produced]
  - **Algorithm**: [Processing algorithm or reference to pseudocode]
  - **Timing**: [Execution timing, frequency requirements]
- **Resource Constraints**: [Memory, stack, CPU time limits]
- **Error Handling**: [Error detection and recovery mechanisms]
- **Safety Mechanisms**: [Monitoring, assertions, bounds checking]
- **Acceptance Criteria**: [Software behavior verification criteria]
- **Verification Method**: [Unit Test/Integration Test/System Test/Analysis]
- **Test Cases**: [Reference to test cases - e.g., "TC-SW-001-001"]
- **Code Implementation**: [Reference to source files - e.g., "firmware/wear_level.c"]
- **Coverage Target**: [100% statement, 100% branch for ASIL-B]
- **MISRA Compliance**: [MISRA C:2012 rule compliance - violations with justification]
- **Dependencies**: [Other software requirements]
- **Status**: [Draft/Approved/Implemented/Verified]

---

## Traceability Links

### Forward Traceability Example:

```
SG-001-01 (Power Loss Safety)
  ├─ FSR-001-01 (Detect power loss)
  │   ├─ SYS-REQ-001-001 (Power supply monitoring)
  │   │   ├─ TSR-HW-001-001 (Power detector circuit)
  │   │   │   └─ TC-HW-001-001 (Verify detection latency < 1ms)
  │   │   └─ TSR-SW-001-001 (Poll power status)
  │   │       └─ TC-SW-001-001 (Verify polling frequency = 100Hz)
```

### Backward Traceability Example:

```
TC-SW-001-001 (Power status polling test)
  └─ TSR-SW-001-001 (Poll power status)
      └─ SYS-REQ-001-001 (Power supply monitoring)
          └─ FSR-001-01 (Detect power loss)
              └─ SG-001-01 (Power loss safety)
```

---

## Requirement Status Workflow

```
Draft → Approved → Implemented → Verified → Baselined
  │        │           │           │          │
  ├─ Review cycle     ├─ Design   ├─ Code   ├─ Testing &
  │                   │  & Design │  Review │  Verification
  └─ Stakeholder OK   └─ Trace OK └─ Trace  └─ All tests
                                    OK         pass
```

---

## Key Principles

1. **One Requirement Per Statement**: Each requirement addresses a single capability
2. **ASIL Inheritance**: Child requirements inherit parent ASIL - cannot reduce ASIL
3. **Bidirectional Traceability**: Every requirement has parent and child links
4. **Objective Acceptance Criteria**: Measurable, verifiable criteria - no ambiguous terms
5. **Complete Allocation**: Every SG/FSR/SYS-REQ must have TSR allocation
6. **Traceability to Tests**: Every requirement must have corresponding test case

---

## Usage Notes

- Copy these templates when creating new requirements
- Keep requirement IDs hierarchical and unique
- Update status as requirement progresses through workflow
- Review and update traceability links during design and implementation
- Use automated traceability tools to identify gaps
