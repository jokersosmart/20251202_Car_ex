# Create New Feature
# PowerShell script to auto-generate feature structure with templates
# Usage: .\create-feature.ps1 -Name "Feature Name" -ASIL "B" -Type "System"

param(
    [Parameter(Mandatory=$true)]
    [string]$Name,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet("A", "B", "C", "D", "QM")]
    [string]$ASIL,
    
    [Parameter(Mandatory=$true)]
    [ValidateSet("Hardware", "Firmware", "System")]
    [string]$Type,
    
    [string]$Owner = $env:USERNAME,
    
    [string]$Stakeholders = "Technical Lead, Safety Manager, Test Lead",
    
    [switch]$Help
)

function Show-Help {
    @"
Create New Feature with ISO 26262 + ASPICE Templates

SYNTAX:
    .\create-feature.ps1 -Name "Feature Name" -ASIL "B" -Type "System" [-Owner "Name"] [-Stakeholders "List"]

PARAMETERS:
    -Name           Feature name (e.g., "Power Loss Protection")
    -ASIL           ASIL level: A, B, C, D, or QM
    -Type           Component type: Hardware, Firmware, or System
    -Owner          Feature owner (default: current user)
    -Stakeholders   Comma-separated list of stakeholders
    -Help           Show this help message

EXAMPLES:
    .\create-feature.ps1 -Name "Wear Leveling" -ASIL "B" -Type "Firmware"
    .\create-feature.ps1 -Name "Power Loss Protection" -ASIL "B" -Type "System" -Owner "John Smith"

OUTPUT:
    Creates: specs/NNN-feature-name/ with all required templates
    - spec.md (overview)
    - requirements.md (SG, FSR, TSR)
    - architecture.md
    - detailed-design.md
    - unit-test-spec.md
    - integration-test-spec.md
    - system-test-spec.md
    - fmea.md
    - fta.md
    - dfa.md
    - traceability.md
    - change-log.md
    - plan.md
    - review-records/ (subdirectory)

"@
}

if ($Help) {
    Show-Help
    exit 0
}

# Function to find next feature ID
function Get-NextFeatureID {
    $specsDir = "specs"
    if (!(Test-Path $specsDir)) {
        return "001"
    }
    
    $existing = Get-ChildItem -Path $specsDir -Directory -ErrorAction SilentlyContinue | 
        Where-Object { $_.Name -match '^\d{3}-' } |
        ForEach-Object { [int]($_.Name.Substring(0, 3)) }
    
    if ($existing) {
        $maxID = ($existing | Measure-Object -Maximum).Maximum
        return ($maxID + 1).ToString("D3")
    }
    return "001"
}

# Function to create feature directory structure
function New-FeatureStructure {
    param(
        [string]$FeatureID,
        [string]$FeatureName,
        [string]$ASIL,
        [string]$Type,
        [string]$Owner,
        [string]$Stakeholders
    )
    
    $slugName = $FeatureName -replace ' ', '-' | % { $_.ToLower() }
    $featureDir = "specs/$FeatureID-$slugName"
    
    # Create main directory
    if (!(Test-Path $featureDir)) {
        New-Item -ItemType Directory -Path $featureDir -Force | Out-Null
        Write-Host "✓ Created directory: $featureDir"
    }
    
    # Create subdirectories
    $subDirs = @("review-records")
    foreach ($subDir in $subDirs) {
        $path = "$featureDir/$subDir"
        if (!(Test-Path $path)) {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
            Write-Host "✓ Created subdirectory: $subDir"
        }
    }
    
    return $featureDir
}

# Function to create template files
function New-TemplateFile {
    param(
        [string]$Path,
        [string]$FeatureID,
        [string]$FeatureName,
        [string]$ASIL,
        [string]$Type,
        [string]$Owner,
        [string]$Stakeholders
    )
    
    $date = Get-Date -Format "yyyy-MM-dd"
    $year = Get-Date -Format "yyyy"
    
    switch (Split-Path -Leaf $Path) {
        "spec.md" {
            @"
# Feature $FeatureID: $FeatureName

**ASIL**: $ASIL  
**Type**: $Type  
**Owner**: $Owner  
**Stakeholders**: $Stakeholders  
**Created**: $date  
**Status**: Planning  

## Executive Summary

[Provide 2-3 sentence overview of feature, its business drivers, and key safety implications]

## Scope

[Define what is included and excluded in this feature]

## Hazard Reference

From HARA analysis:
- **Hazard ID**: [e.g., H-3.2]
- **Severity**: [S1-S4]
- **Exposure**: [E1-E4]
- **Controllability**: [C1-C3]
- **ASIL**: $ASIL

## Key Milestones

- Requirements Review: [Date]
- Design Review: [Date]
- Code Review: [Date]
- Verification Complete: [Date]

---

**See Also**:
- [requirements.md](requirements.md) - All requirements (SG, FSR, TSR)
- [architecture.md](architecture.md) - System architecture
- [detailed-design.md](detailed-design.md) - Detailed design
- [traceability.md](traceability.md) - Complete traceability matrix
"@
        }
        "requirements.md" {
            @"
# Feature $FeatureID: Requirements

**Feature ID**: $FeatureID  
**Feature Name**: $FeatureName  
**ASIL Level**: $ASIL  
**Document Type**: Requirements Specification  
**Created**: $date  

## Overview

This document specifies all requirements for feature $FeatureID following ISO 26262 hierarchical structure:

Safety Goals (SG) → Functional Safety Requirements (FSR) → System Requirements (SYS-REQ) → Technical Safety Requirements (TSR-HW/TSR-SW)

---

## Safety Goals (SG)

### SG-$FeatureID-01: [Safety Goal Title]

- **Description**: [What hazard is being addressed - from HARA]
- **Hazard Reference**: [Link to HARA output]
- **ASIL**: $ASIL
- **Rationale**: [Why this goal is necessary]
- **Acceptance Criteria**: [How we know goal is achieved]

---

## Functional Safety Requirements (FSR)

### FSR-$FeatureID-01: [FSR Title]

- **Description**: [Functional capability implementing safety goal]
- **Derives From**: SG-$FeatureID-01
- **Type**: [Detection/Prevention/Mitigation/Recovery]
- **ASIL**: $ASIL (inherited)
- **Priority**: Mandatory
- **Rationale**: [Technical justification]
- **Acceptance Criteria**: [Measurable pass/fail criteria]

---

## System Requirements (SYS-REQ)

### SYS-REQ-$FeatureID-001: [System Requirement Title]

- **Description**: [Clear, testable system-level requirement]
- **Derives From**: FSR-$FeatureID-01
- **ASIL**: $ASIL (inherited)
- **Functional Scope**: [Boundaries and included/excluded items]
- **Constraints**: [Timing, power, resource constraints]
- **Allocated Components**: [Hardware/Firmware modules responsible]
- **Acceptance Criteria**: [Objective, measurable criteria]
- **Verification Method**: [Test/Analysis/Inspection/Demonstration]
- **Status**: Draft

---

## Technical Safety Requirements (TSR)

### TSR-HW-$FeatureID-001: [Hardware TSR Title]

- **Description**: [Hardware-specific implementation]
- **Derives From**: SYS-REQ-$FeatureID-001
- **Component**: [Hardware module name]
- **ASIL**: $ASIL
- **Type**: [Detection/Protection/Monitoring]
- **Functional Specification**: [Inputs/outputs/behavior]
- **Safety Mechanisms**: [Built-in safety features]
- **Acceptance Criteria**: [Verification criteria]
- **RTL Implementation**: [Reference to RTL files]
- **Status**: Draft

### TSR-SW-$FeatureID-001: [Software TSR Title]

- **Description**: [Software/firmware-specific implementation]
- **Derives From**: SYS-REQ-$FeatureID-001
- **Module**: [Firmware module name]
- **ASIL**: $ASIL
- **Type**: [Algorithm/State Machine/Monitoring]
- **Functional Specification**: [Inputs/outputs/algorithm]
- **Resource Constraints**: [Memory, CPU, timing limits]
- **Error Handling**: [Error detection and recovery]
- **Acceptance Criteria**: [Verification criteria]
- **Code Implementation**: [Reference to source files]
- **Coverage Target**: 100% statement, 100% branch
- **Status**: Draft

---

## Traceability Links

| SG | FSR | SYS-REQ | TSR-HW | TSR-SW | Design | Code | Tests |
|----|-----|---------|--------|--------|--------|------|-------|
| $FeatureID-01 | $FeatureID-01 | $FeatureID-001 | $FeatureID-001 | $FeatureID-001 | [✓] | [TBD] | [TBD] |

---

**Status**: Draft (awaiting requirements review)
"@
        }
        "architecture.md" {
            @"
# Feature $FeatureID: Architecture

**Feature ID**: $FeatureID  
**Feature Name**: $FeatureName  
**Type**: $Type  
**Created**: $date

## Overview

This document describes the high-level architecture for feature $FeatureID, including system decomposition, component interactions, and interface specifications.

## Architecture Overview

### System Block Diagram

[ASCII diagram or high-level block structure showing major components]

```
    Component A
         |
         v
    +---------+
    |   Main  |
    |  Logic  |
    +---------+
         |
         v
    Component B
```

## Component Decomposition

### Hardware Components

| Component | Purpose | Interfaces | ASIL |
|-----------|---------|-----------|------|
| [Component name] | [Purpose] | [Input/output signals] | $ASIL |

### Software Modules

| Module | Purpose | Interfaces | ASIL |
|--------|---------|-----------|------|
| [Module name] | [Purpose] | [Function calls, data] | $ASIL |

## Interface Specifications

### Hardware-Software Interface

**Signal**: [Signal name]
- Direction: [Input/Output]
- Voltage levels: [e.g., 3.3V CMOS]
- Timing: [Propagation delay, setup/hold times]

### External Interfaces

**Protocol**: [e.g., NVMe, PCIe]
- Physical layer: [Electrical specs]
- Logical layer: [Message formats]
- Timing requirements: [Latency, throughput]

## Architectural Decisions

| Decision | Rationale | Alternatives Considered |
|----------|-----------|----------------------|
| [Design choice] | [Why chosen] | [Why not chosen] |

## Safety Mechanisms

- **Redundancy**: [Where applied]
- **Monitoring**: [What is monitored]
- **Fault Detection**: [Detection methods]
- **Fault Isolation**: [Isolation approach]

## Performance Characteristics

- **Latency**: [Critical timing requirements]
- **Power**: [Power consumption targets]
- **Area**: [If hardware - area budget]
- **Throughput**: [Data rate requirements]

---

**See Also**:
- [requirements.md](requirements.md) - System requirements
- [detailed-design.md](detailed-design.md) - Detailed design
- [traceability.md](traceability.md) - Requirement-to-design mapping
"@
        }
        "detailed-design.md" {
            @"
# Feature $FeatureID: Detailed Design

**Feature ID**: $FeatureID  
**Created**: $date

## Design Overview

This document provides detailed design specifications for implementing feature $FeatureID, including algorithms, state machines, timing analysis, and safety mechanism implementation details.

## Hardware Design Details

### Circuit Design

**Component**: [Component name]
- **Technology**: [e.g., CMOS, Analog comparator]
- **Schematic Reference**: [RTL file or schematic location]
- **Design Constraints**: [Area, power, temperature ranges]

### Timing Analysis

**Critical Path**: [Description of longest timing path]
- Path delay: [Calculated delay]
- Setup/hold margins: [Margin values]
- Process/temperature/voltage corners: [PVT analysis]

### Safety Mechanism Implementation

**Redundancy**: [Explain redundant implementation]
**Error Detection**: [How errors are detected]
**Containment**: [How failures are contained]

## Software Design Details

### Algorithm

**Purpose**: [What this algorithm does]

**Pseudocode**:
\`\`\`
function algorithm_name(inputs):
    [Detailed algorithm steps]
    return result
\`\`\`

**Complexity Analysis**:
- Time complexity: [Big-O analysis]
- Space complexity: [Memory usage]
- Worst-case execution time: [WCET]

### State Machine

**States**: [Define all states]
**Transitions**: [Trigger conditions for state transitions]

\`\`\`
    [State 1]
         |
        [Condition]
         |
         v
    [State 2]
\`\`\`

### Error Handling

**Error Scenarios**:
| Error | Detection | Recovery |
|-------|-----------|----------|
| [Error type] | [Detection method] | [Recovery action] |

### Resource Usage

| Resource | Budget | Used | Margin |
|----------|--------|------|--------|
| Memory | [bytes] | [bytes] | [%] |
| CPU time | [ms] | [ms] | [%] |
| Power | [mW] | [mW] | [%] |

## Detailed Design-to-Requirement Tracing

| Requirement | Design Implementation | Location |
|-------------|----------------------|----------|
| SYS-REQ-$FeatureID-001 | [Design detail] | [File/line reference] |

---

**See Also**:
- [requirements.md](requirements.md) - Requirements this implements
- [unit-test-spec.md](unit-test-spec.md) - How design will be tested
"@
        }
        "unit-test-spec.md" {
            @"
# Feature $FeatureID: Unit Test Specification

**Feature ID**: $FeatureID  
**Test Type**: Unit Test  
**Coverage Target**: 100% statement, 100% branch  

## Overview

Unit tests verify individual components (RTL modules, C functions) meet their specifications in isolation.

## Hardware Unit Tests

### TC-HW-$FeatureID-001: [Test Case Title]

**Objective**: [What is being tested]

**Derives From**: TSR-HW-$FeatureID-001

**Test Setup**:
- Test bench: [Simulation/hardware setup]
- Stimuli: [Input signals/commands]
- Measurement points: [What to observe]

**Test Steps**:
1. [Step 1]
2. [Step 2]

**Expected Results**:
- [Expected behavior]
- [Measured values]

**Acceptance Criteria**:
- [Pass/fail condition]
- [Coverage requirement]

---

## Software Unit Tests

### TC-SW-$FeatureID-001: [Test Case Title]

**Objective**: [What is being tested]

**Derives From**: TSR-SW-$FeatureID-001

**Test Code Reference**: [Source code file and function]

**Test Preconditions**:
- [Initial state]
- [Setup required]

**Test Inputs**:
- [Input parameters]
- [Test data]

**Expected Results**:
- [Return values]
- [State changes]

**Acceptance Criteria**:
- [Pass/fail condition]
- [Coverage requirement: 100% statement, 100% branch]

---

## Coverage Metrics

**Target**: 100% statement, 100% branch

| Metric | Target | Measured | Status |
|--------|--------|----------|--------|
| Statement coverage | 100% | [TBD] | [TBD] |
| Branch coverage | 100% | [TBD] | [TBD] |

**Coverage Tool**: [Tool used - e.g., VCS, Verilog coverage]

---

**See Also**:
- [detailed-design.md](detailed-design.md) - Design being tested
- [integration-test-spec.md](integration-test-spec.md) - Integration tests
"@
        }
        "integration-test-spec.md" {
            @"
# Feature $FeatureID: Integration Test Specification

**Feature ID**: $FeatureID  
**Test Type**: Integration Test  

## Overview

Integration tests verify that components work together correctly and that interfaces are properly implemented.

## Test Cases

### TC-INT-$FeatureID-001: [Integration Scenario]

**Objective**: [What scenario is being tested]

**Components Involved**:
- [Component 1]
- [Component 2]

**Test Setup**:
- [Test environment]
- [Preconditions]

**Test Scenario**:
1. [Step 1]
2. [Step 2]
3. [Verify result]

**Expected Results**:
- [Expected behavior]
- [Component interactions]

**Acceptance Criteria**:
- [Pass/fail criteria]

---

## Coverage

**Integration Path Coverage**: [Percentage of component interactions covered]

| Interaction | Covered | Test Case |
|------------|---------|-----------|
| [Component A] ↔ [Component B] | [✓] | TC-INT-$FeatureID-001 |

---

**See Also**:
- [unit-test-spec.md](unit-test-spec.md) - Unit tests
- [system-test-spec.md](system-test-spec.md) - System-level tests
"@
        }
        "system-test-spec.md" {
            @"
# Feature $FeatureID: System Test Specification

**Feature ID**: $FeatureID  
**Test Type**: System/Qualification Test  

## Overview

System tests verify that the complete feature meets all customer requirements and safety goals.

## System Test Cases

### TC-SYS-$FeatureID-001: [System Requirement Verification]

**Objective**: [Verify system requirement is met]

**Derives From**: SYS-REQ-$FeatureID-001

**Test Environment**:
- [Hardware/simulation setup]
- [Real-world conditions if applicable]

**Test Scenario**:
1. [Step 1 - Setup]
2. [Step 2 - Execute]
3. [Step 3 - Verify]

**Expected Results**:
- [Requirement satisfied]
- [Measurable outcomes]

**Acceptance Criteria**:
- [Objective measurement]
- [Pass/fail conditions]

---

## Requirement Verification Matrix

| Requirement | Test Case | Status |
|-------------|-----------|--------|
| SYS-REQ-$FeatureID-001 | TC-SYS-$FeatureID-001 | [✓] |

---

**See Also**:
- [requirements.md](requirements.md) - All system requirements
- [unit-test-spec.md](unit-test-spec.md) - Unit tests
"@
        }
        "fmea.md" {
            @"
# Feature $FeatureID: Failure Mode and Effects Analysis (FMEA)

**Feature ID**: $FeatureID  
**ASIL Level**: $ASIL  
**Created**: $date

## FMEA Summary

| ID | Failure Mode | Severity | Occurrence | Detection | RPN | Mitigation | Residual |
|----|---|---|---|---|---|---|---|
| FM-001 | [Failure mode] | [1-10] | [1-10] | [1-10] | [RPN] | [Action] | [Residual] |

---

## Detailed FMEA Analysis

### FM-001: [Failure Mode]

**Failure Definition**: [Specific failure mode]

**Root Causes**:
- [Cause 1]
- [Cause 2]

**Effects**:
- Immediate: [Direct effect]
- Downstream: [System-level consequence]

**Severity (S)**: [1-10] - [Description]

**Occurrence (O)**: [1-10] - [Probability justification]

**Detection (D)**: [1-10] - [Current detection methods]

**Risk Priority Number (RPN)**: S × O × D = [Value]

**Mitigation Actions**:
1. [Design-in prevention/detection]
2. [Monitoring strategy]

**Residual Risk**: [Residual RPN after mitigation]

---

## Summary

**Total Failure Modes**: [Number]

**High RPN Items** (RPN > 150): [List items requiring immediate action]

**Mitigation Status**: [In-progress/Complete]

---

**See Also**:
- [fta.md](fta.md) - Fault tree analysis
- [dfa.md](dfa.md) - Dependent failure analysis
"@
        }
        "fta.md" {
            @"
# Feature $FeatureID: Fault Tree Analysis (FTA)

**Feature ID**: $FeatureID  
**ASIL Level**: $ASIL  
**Created**: $date

## Top Event

**Event**: [Undesirable event that compromises safety goal]

**Description**: [Clear definition of top event]

## Fault Tree Structure

\`\`\`
        Top Event
             |
        _____|_____
       |           |
    Event 1     Event 2
       |
    ___+___
   |       |
 Fail 1  Fail 2
\`\`\`

## Minimal Cut Sets

**First-Order Cut Sets** (single component failure):
- [Component failure that directly causes top event]

**Second-Order Cut Sets** (two independent failures):
- [Component 1] AND [Component 2]

**Higher-Order Cut Sets**:
- [Three or more failures required]

## Quantitative Analysis

**Probability Calculation**:
- Top event probability target: [e.g., < 1e-7 per hour]
- Component failure rates: [From reliability data]
- Residual probability: [After mitigation]

---

**See Also**:
- [fmea.md](fmea.md) - Failure mode analysis
- [dfa.md](dfa.md) - Dependent failure analysis
"@
        }
        "dfa.md" {
            @"
# Feature $FeatureID: Dependent Failure Analysis (DFA)

**Feature ID**: $FeatureID  
**ASIL Level**: $ASIL  
**Created**: $date

## Common Cause Failure Analysis

### CCF Category 1: [Systematic Failure]

**Potential Cause**: [Environmental/design/manufacturing cause affecting multiple components]

**Affected Components**:
- [Component A]
- [Component B]

**Mitigation Strategy**:
- [Design approach to prevent common cause]

**Residual Risk**: [Remaining exposure]

---

### CCF Category 2: [Parametric Stress]

**Stress Type**: [e.g., Temperature, voltage, radiation]

**Affected Components**:
- [Component affected]

**Mitigation**:
- [Monitoring or derating]

---

## Cascading Failure Analysis

### Failure Propagation Path 1

**Primary Failure**: [Initial failure]
  → **Secondary Effect**: [First consequence]
    → **Tertiary Effect**: [Further propagation]

**Mitigation**: [Firewall/isolation mechanism]

---

## Failure Propagation Matrix

| Failure Source | Path 1 | Path 2 | Mitigation |
|---|---|---|---|
| [Failure] | [Consequence] | [Secondary] | [Action] |

---

**See Also**:
- [fmea.md](fmea.md) - Failure mode analysis
- [fta.md](fta.md) - Fault tree analysis
"@
        }
        "traceability.md" {
            @"
# Feature $FeatureID: Traceability Matrix

**Feature ID**: $FeatureID  
**Feature Name**: $FeatureName  
**Created**: $date

## Forward Traceability (Requirements → Implementation)

| SG | FSR | SYS-REQ | TSR-HW | TSR-SW | Design | Code | Test | Status |
|----|-----|---------|--------|--------|--------|------|------|--------|
| [ID] | [ID] | [ID] | [ID] | [ID] | [✓/✗] | [✓/✗] | [✓/✗] | [Status] |

---

## Backward Traceability (Implementation → Requirements)

| Code File | Function | TSR-HW/SW | SYS-REQ | FSR | Justified |
|-----------|----------|-----------|---------|-----|-----------|
| [File] | [Function] | [ID] | [ID] | [ID] | [✓/✗] |

---

## Test Coverage

| Requirement | Test Case | Type | Status |
|-------------|-----------|------|--------|
| [Requirement] | [Test ID] | [Unit/Int/Sys] | [✓/✗] |

---

## Coverage Gaps

| Gap | Cause | Remediation | Owner | Due Date |
|----|-------|-------------|-------|----------|
| [Missing item] | [Why] | [Action] | [Owner] | [Date] |

---

**Metrics**:
- Requirements coverage: [%]
- Code traceability: [%]
- Test coverage: [%]

---

**Last Updated**: $date
"@
        }
        "change-log.md" {
            @"
# Feature $FeatureID: Change Log

**Feature ID**: $FeatureID  
**Feature Name**: $FeatureName

## Version History

| Version | Date | Author | Change | Reason | Approved |
|---------|------|--------|--------|--------|----------|
| 0.1 | $date | $Owner | Initial creation | Feature kickoff | - |

---

## Change Records

### Change 001: [Change Title]

**Date**: [Date]  
**Type**: [Requirement/Design/Implementation/Test]  
**Impact**: [What changed]

**Affected Items**:
- [Requirement changed]
- [Design file updated]
- [Test case added]

**Justification**: [Why this change was necessary]

**Sign-off**: _____________________ Date: _______

---

## Superseded Versions

[Archive old versions with dates]

---

**Current Status**: Draft (not yet released)
"@
        }
        "plan.md" {
            @"
# Feature $FeatureID: Implementation Plan

**Feature ID**: $FeatureID  
**Feature Name**: $FeatureName  
**ASIL Level**: $ASIL  
**Target Completion**: [Date - TBD]

## Summary

[2-3 sentence summary of feature and approach]

## Phases and Timeline

### Phase 1: Requirements (Weeks 1-2)
- [ ] Requirements review meeting
- [ ] Stakeholder approval
- [ ] Requirements baselined

### Phase 2: Design (Weeks 3-4)
- [ ] Architecture review
- [ ] Design review
- [ ] Design documentation complete

### Phase 3: Implementation (Weeks 5-7)
- [ ] Hardware/Firmware implementation
- [ ] Code review
- [ ] Code complete

### Phase 4: Verification (Weeks 8-10)
- [ ] Unit tests complete
- [ ] Integration tests complete
- [ ] System tests complete

### Phase 5: Safety Validation (Week 11)
- [ ] Safety analysis review
- [ ] Verification review
- [ ] Final approval

### Phase 6: Release (Week 12)
- [ ] Baseline creation
- [ ] Documentation archival
- [ ] Feature released

## Resource Allocation

| Role | Name | Allocation | Responsibilities |
|------|------|-----------|------------------|
| Requirements Lead | [Name] | [%] | Requirements, ASPICE |
| Hardware Lead | [Name] | [%] | RTL design, HW verification |
| Software Lead | [Name] | [%] | Firmware, SW verification |
| Safety Manager | [Name] | [%] | Safety analysis, reviews |
| Test Lead | [Name] | [%] | Test planning, execution |

## Risk Assessment

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|-----------|
| [Risk] | [L/M/H] | [L/M/H] | [Action] |

---

**Next Milestone Review**: [Date]

**See Also**: [requirements.md](requirements.md), [fmea.md](fmea.md)
"@
        }
        default {
            ""
        }
    }
}

# Main execution
$featureID = Get-NextFeatureID
$featureDir = New-FeatureStructure -FeatureID $featureID -FeatureName $Name -ASIL $ASIL -Type $Type -Owner $Owner -Stakeholders $Stakeholders

# Create all template files
$templates = @(
    "spec.md",
    "requirements.md",
    "architecture.md",
    "detailed-design.md",
    "unit-test-spec.md",
    "integration-test-spec.md",
    "system-test-spec.md",
    "fmea.md",
    "fta.md",
    "dfa.md",
    "traceability.md",
    "change-log.md",
    "plan.md"
)

foreach ($template in $templates) {
    $filePath = "$featureDir/$template"
    $content = New-TemplateFile -Path $filePath -FeatureID $featureID -FeatureName $Name -ASIL $ASIL -Type $Type -Owner $Owner -Stakeholders $Stakeholders
    
    if ($content) {
        Set-Content -Path $filePath -Value $content -Encoding UTF8
        Write-Host "✓ Created template: $template"
    }
}

# Create review record templates
$reviewRecords = @(
    "requirements-review.md",
    "design-review.md",
    "code-review.md",
    "verification-review.md"
)

foreach ($record in $reviewRecords) {
    $filePath = "$featureDir/review-records/$record"
    $content = @"
# Review: $($record -replace '-review.md', '')

**Date**: [Date]  
**Attendees**: [List]  
**Feature**: $featureID - $Name

## Review Checklist

- [ ] [Check 1]
- [ ] [Check 2]

## Issues

[Issues raised during review]

## Sign-off

✓ Approved by: _____________________ Date: _______

"@
    Set-Content -Path $filePath -Value $content -Encoding UTF8
    Write-Host "✓ Created review template: $record"
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "Feature Created Successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Feature ID: $featureID" -ForegroundColor Yellow
Write-Host "Feature Name: $Name" -ForegroundColor Yellow
Write-Host "Directory: $featureDir" -ForegroundColor Yellow
Write-Host "ASIL Level: $ASIL" -ForegroundColor Yellow
Write-Host "Component Type: $Type" -ForegroundColor Yellow
Write-Host "Owner: $Owner" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Review $featureDir/spec.md"
Write-Host "2. Complete $featureDir/requirements.md"
Write-Host "3. Schedule requirements review"
Write-Host "4. Follow Feature Creation Guide: docs/framework/guides/FEATURE-CREATION-GUIDE.md"
Write-Host ""
