# Safety Analysis Templates (ISO 26262-9)

## FMEA Template (Failure Mode and Effects Analysis)

### FMEA: [Feature Name] - [Component/System]

**Document ID**: FMEA-[XXX]-[YY]  
**Feature**: [Feature number and name]  
**Component**: [Hardware/Software component analyzed]  
**ASIL Level**: [A/B/C/D]  
**Prepared By**: [Name/Date]  
**Reviewed By**: [Safety Manager]  
**Status**: [Draft/Approved/In Review]

---

### FMEA Analysis Table

| ID | Failure Mode | Failure Causes | Failure Effects | Severity (S) | Occurrence (O) | Detection (D) | RPN | Mitigation Action | Residual Risk | Status |
|----|---|---|---|---|---|---|---|---|---|---|
| **FM-001** | [Specific failure mode] | [Root causes] | [Immediate & downstream effects] | [1-10] | [1-10] | [1-10] | [S×O×D] | [Designed-in prevention or detection] | [Residual S×O×D] | ✓ |
| **FM-002** | [Example: Data corruption] | [Bit flip from radiation] | [Incorrect wear level value] | 9 | 3 | 7 | 189 | ECC-protected memory + online ECC check | 189→42 | ✓ |

---

### Severity Scale (S)

| Level | Definition | Examples |
|-------|-----------|----------|
| 10 | No warning - safety-critical loss | Undetected power loss → data corruption |
| 9 | Some warning - safety goal violation | Detected power loss but too late |
| 8 | Significant impairment | Wear level inaccuracy → uneven wear |
| 7 | Moderate impact | Temporary performance degradation |
| 5-6 | Minor impact | Recoverable error condition |
| 1-4 | Negligible impact | Non-critical system impact |

---

### Occurrence Scale (O)

| Level | Probability | Per Billion Hours |
|-------|----------|-----------------|
| 10 | Very likely | ≥ 100,000 |
| 9 | High | 10,000-100,000 |
| 8 | High | 1,000-10,000 |
| 6-7 | Medium | 10-1,000 |
| 4-5 | Low | 1-10 |
| 2-3 | Very low | < 0.01 |
| 1 | Remote | < 0.001 |

---

### Detection Scale (D)

| Level | Detection Method | Confidence |
|-------|-----------------|-----------|
| 10 | No detection possible | Failure undetectable |
| 9 | Very unlikely | Detection probability < 10% |
| 8 | Unlikely | Detection probability 10-25% |
| 6-7 | Moderate | Detection probability 25-75% |
| 4-5 | Good | Detection probability 75-90% |
| 2-3 | Very good | Detection probability 90-99% |
| 1 | Certain detection | 100% detection rate |

---

### Mitigation Actions Examples

- **Design-in Prevention**: Redundancy, error-correcting codes, monitoring circuits
- **Design-in Detection**: Parity checks, CRC, heartbeat monitors, watchdog timers
- **Operational Detection**: System-level monitoring, firmware checks
- **Containment**: Fault isolation, graceful degradation

---

### RPN Decision Matrix

| RPN Range | Action Required |
|-----------|-----------------|
| ≥ 200 | Unacceptable - Must redesign |
| 150-199 | Very High - Immediate mitigation required |
| 100-149 | High - Significant mitigation required |
| 50-99 | Medium - Mitigation recommended |
| < 50 | Acceptable - Document and track |

---

## FTA Template (Fault Tree Analysis)

### FTA: [Feature Name] - [Top-Level Event]

**Document ID**: FTA-[XXX]-[YY]  
**Feature**: [Feature number and name]  
**Top Event**: [Undesirable event to prevent]  
**ASIL Level**: [A/B/C/D]  
**Prepared By**: [Name/Date]  
**Status**: [Draft/Approved]

---

### Top-Level Event Definition

**Top Event**: [Specific undesirable event]  
**Description**: [Clear definition of what constitutes the top event]  
**Impact**: [Safety/performance consequences]  
**Probability Target**: [e.g., < 1e-9 per hour for ASIL-B]

---

### Example Fault Tree

```
                    Top Event: Data Corruption
                           |
                ___________+___________
               |                       |
        Undetected      Detected but
        Data Error      Not Recovered
             |                 |
        _____+_____         ____+____
       |     |     |       |        |
     ECC   Parity Bit    Recovery  Backup
     Fail   Flip   Error  Failed    Lost
```

---

### Cut Set Analysis

**Minimal Cut Sets**: Combination of component failures that directly cause the top event

**Single Point Failures** (1st order cut sets):
- [Component/Function] failure → Top event
- Example: ECC failure → Undetected data corruption

**Common Cause Failures** (2nd order cut sets):
- [Component 1] AND [Component 2] failure → Top event
- Example: ECC AND parity check fail simultaneously

**Higher Order Combinations** (3rd+ order):
- Multiple independent failures required for top event
- Lower probability, acceptable for ASIL-B/C

---

### Quantitative Analysis

| Basic Event | Failure Rate | Probability (1 year) |
|-------------|--------------|-------------------|
| ECC Failure | 1e-6/hr | 8.76e-3 |
| Parity Check Fail | 1e-7/hr | 8.76e-4 |
| Both ECC & Parity Fail | (1e-6) × (1e-7) | 8.76e-13 |

---

## DFA Template (Dependent Failure Analysis)

### DFA: [Feature Name] - [Failure Mode]

**Document ID**: DFA-[XXX]-[YY]  
**Feature**: [Feature number and name]  
**System**: [Component/subsystem analyzed]  
**Focus**: [Common cause or cascading failure category]  
**Prepared By**: [Name/Date]

---

### Common Cause Failure Analysis

**Category**: [Systematic/Parametric/Extrinsic]

| Potential CCP | Affected Components | Mitigation | Status |
|---|---|---|---|
| **Thermal stress** | All silicon | Design thermal monitoring; De-rating | ✓ |
| **Voltage variation** | Power distribution | Supply filtering; On-die regulator | ✓ |
| **Radiation (high altitude/automotive)** | Memory cells | ECC + scrubbing; Redundancy | ✓ |
| **Manufacturing defect** | Varies | In-circuit testing; Burn-in | ✓ |

---

### Cascading Failure Analysis

**Primary Failure**: [Initial component/function failure]  
**Secondary Effects**: [Downstream failures triggered]  
**Tertiary Effects**: [Further propagation]  
**Mitigation**: [Firewall/isolation/shutdown mechanisms]

**Example**:
```
Primary: Power supply voltage sag
  → Secondary: Flash controller timeout
    → Tertiary: Incomplete write command
      → Outcome: Data corruption
Mitigation: Voltage monitoring + graceful shutdown
```

---

### Failure Propagation Matrix

| Failure Source | Propagation Path 1 | Propagation Path 2 | Propagation Path 3 |
|---|---|---|---|
| Power anomaly | → Detector timeout | → Write abort | → Data loss |
| Clock glitch | → ECC error | → FIFO underflow | → Command mismatch |
| Thermal runaway | → Leakage increase | → Timing violation | → System reset |

---

## Safety Analysis Integration with Requirements

### FMEA-to-Requirements Traceability

| Failure Mode | Severity | Mitigation Type | Implementing Requirement |
|---|---|---|---|
| Data corruption (bit flip) | 9 | Detection | TSR-HW-001-001 (ECC circuit) |
| Power loss | 9 | Detection | TSR-SW-002-001 (Power monitor) |
| Temperature excursion | 7 | Prevention | TSR-HW-003-001 (Thermal sensor) |

### FTA-to-Requirements Mapping

**Top Event**: Undetected power loss  
**Minimal Cut Set**: Power detector fails OR Monitor not responding  
**Mitigation Requirements**:
- TSR-HW-001-001: Implement redundant power detectors
- TSR-SW-002-001: Monitor detector heartbeat signal
- TSR-SW-003-001: Log detection failures

---

## Review Checklist for Safety Analysis

- [ ] All potential failure modes identified
- [ ] Severity ratings justified with hazard analysis reference
- [ ] Occurrence and detection ratings based on design data
- [ ] RPN calculations correct
- [ ] High-RPN items have documented mitigations
- [ ] Residual risk acceptable for ASIL level
- [ ] Mitigations traced to requirements
- [ ] Common cause failures analyzed
- [ ] Cascading failures identified and contained
- [ ] Analysis covers both hardware and software
- [ ] Safety goals addressed in analysis
- [ ] Review team includes safety specialist
- [ ] Baseline established for future audits

---

## Update Strategy

Safety analyses are living documents - update when:

1. **Design changes**: Mitigation effectiveness may change
2. **Field data received**: Occurrence rates updated from experience
3. **New failure modes identified**: Lessons learned incorporated
4. **Requirements change**: Coverage analysis revisited
5. **Process improvements**: Detection methods enhanced

Update date and version number with each revision.
