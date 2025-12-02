# Process Guide: Feature Specification Framework

**Purpose**: Detailed process instructions for teams implementing the ISO 26262 + ASPICE framework  
**Audience**: Process managers, technical leads, quality assurance engineers  
**Version**: 1.0.0

---

## Process Overview

The Feature Specification Framework establishes a structured, traceable approach to developing safety-critical features (SSD controller components) that comply with:

- **ISO 26262-1:2018** - Functional Safety for Automotive Electrical/Electronic Systems
- **ASPICE CL3** - Automotive Software Process Improvement and Capability Determination (Capability Level 3)

### Seven-Phase Feature Development Lifecycle

```
Phase 1: Initialization
  ↓
Phase 2: Requirements Analysis
  ↓
Phase 3: Architecture & Design
  ↓
Phase 4: Safety Analysis
  ↓
Phase 5: Implementation & Verification
  ↓
Phase 6: Review & Approval
  ↓
Phase 7: Baseline & Release
```

---

## Process Details

### Phase 1: Feature Initialization (1-2 days)

**Goal**: Establish feature scope, ASIL level, and project structure

**Inputs**:
- Hazard Analysis and Risk Assessment (HARA) output
- Product requirements
- Customer specifications

**Activities**:

1. **Define Feature Scope**
   - What hazard or requirement does this address?
   - What's in/out of scope?
   - Any dependencies with other features?

2. **Determine ASIL Level**
   - From HARA analysis: Severity × Exposure × Controllability
   - ASIL A (lowest) → D (highest)
   - SSD safety features typically ASIL-B/C

3. **Assign Ownership**
   - Feature Owner (technical lead)
   - Requirements Lead
   - Hardware Lead (if HW component)
   - Software Lead (if FW component)
   - Safety Manager
   - Test Lead

4. **Create Feature Structure**
   ```powershell
   .\create-feature.ps1 -Name "Feature Name" -ASIL "B" -Type "System"
   ```

**Outputs**:
- Feature directory with all templates
- Feature ID assigned
- Initial feature overview

**Review Gate**: Feature Kickoff Review
- Stakeholders confirm scope and ASIL
- Resource allocation approved
- Schedule agreed

---

### Phase 2: Requirements Analysis (3-5 days)

**Goal**: Establish complete, traceable requirements hierarchy

**Activities**:

1. **Define Safety Goals (SG)**
   - From hazard: What safety outcome must be achieved?
   - Template: [REQUIREMENTS-TEMPLATE.md](../templates/REQUIREMENTS-TEMPLATE.md)
   - Stakeholder review required

2. **Derive Functional Safety Requirements (FSR)**
   - What functional capabilities implement safety goals?
   - Multiple FSRs may implement one SG
   - Document Type (Detection/Prevention/Mitigation/Recovery)

3. **Develop System Requirements (SYS-REQ)**
   - What must the system do to implement FSR?
   - Functional scope, interfaces, constraints
   - Acceptance criteria (measurable)

4. **Allocate Technical Safety Requirements (TSR)**
   - TSR-HW: Hardware components responsible
   - TSR-SW: Software/firmware modules responsible
   - Every SYS-REQ → TSR-HW AND/OR TSR-SW

5. **Establish Bidirectional Traceability**
   - Forward: SG → FSR → SYS-REQ → TSR
   - Backward: TSR → SYS-REQ → FSR → SG
   - Use traceability matrix template

**Key Principle**: Every requirement is ASIL-aware and verifiable

```markdown
SYS-REQ-001-001: Power Detection
- Derives From: FSR-001-01 (Detect power loss)
- ASIL: B (inherited from SG)
- Acceptance Criteria: Detection latency < 1ms
- Verification Method: Test + Analysis
```

**Outputs**:
- requirements.md (complete SG/FSR/SYS-REQ/TSR hierarchy)
- traceability.md (initial traceability matrix)
- Architecture decisions documented

**Review Gate**: Requirements Review
- Checklist:
  - [ ] All requirements clear and unambiguous
  - [ ] All requirements traceable (forward and backward)
  - [ ] All acceptance criteria objective and measurable
  - [ ] ASIL levels correct
  - [ ] No contradictions between requirements
  - [ ] All hazards from HARA addressed
- Approval: Technical Lead + Safety Manager

---

### Phase 3: Architecture & Detailed Design (4-7 days)

**Goal**: Decompose requirements into implementable designs

**Activities**:

1. **System Architecture Design**
   - Block diagrams showing components and interactions
   - Interface specifications (electrical, logical, timing)
   - Allocation of requirements to components

2. **Hardware Architecture (if applicable)**
   - RTL module decomposition
   - Inter-module interfaces
   - Timing analysis (critical paths)
   - Design for testability (DFT) features

3. **Software Architecture (if applicable)**
   - Module/function decomposition
   - Data structures and algorithms
   - State machines (if applicable)
   - Resource budgets (memory, CPU, timing)

4. **Detailed Design**
   - Logic/algorithm pseudocode
   - Timing verification (WCET analysis)
   - Safety mechanism implementation details
   - Error handling strategies

5. **Design-to-Requirements Mapping**
   - Verify each requirement has design implementation
   - Maintain traceability links

**Outputs**:
- architecture.md
- detailed-design.md
- Timing analysis reports
- Design review records

**Review Gate**: Design Review
- Checklist:
  - [ ] Architecture addresses all requirements
  - [ ] Timing constraints satisfied
  - [ ] Safety mechanisms properly designed
  - [ ] Design is testable
  - [ ] Design quality acceptable (ASPICE SWE.2, HWE.2)
- Approval: Technical Lead + Architects

---

### Phase 4: Safety Analysis (3-5 days)

**Goal**: Identify and mitigate failure modes

**Activities**:

1. **FMEA (Failure Mode and Effects Analysis)**
   - Identify all potential failure modes
   - Assess severity/occurrence/detection (SOD)
   - Calculate Risk Priority Number (RPN)
   - Propose mitigations for high-RPN items
   - Template: [SAFETY-ANALYSIS-TEMPLATE.md](../templates/SAFETY-ANALYSIS-TEMPLATE.md)

2. **FTA (Fault Tree Analysis)**
   - Define top-level undesirable event
   - Construct fault tree showing cause-effect relationships
   - Identify minimal cut sets
   - Calculate probability of top event

3. **DFA (Dependent Failure Analysis)**
   - Identify common cause failures (CCF)
   - Analyze cascading failure scenarios
   - Develop mitigation for dependent failures

4. **Traceability: Safety Analysis → Requirements**
   - Each FMEA mitigation → Implementing requirement
   - Example: "Dual redundant detectors" → TSR-HW-001-001

**Outputs**:
- fmea.md (Failure modes with mitigations)
- fta.md (Fault tree and probability analysis)
- dfa.md (Common cause and cascading failures)

**Review Gate**: Safety Analysis Review
- Checklist:
  - [ ] All failure modes identified
  - [ ] RPN calculations correct
  - [ ] High-RPN items have documented mitigations
  - [ ] Mitigations traced to requirements
  - [ ] Common cause failures analyzed
  - [ ] Residual risk acceptable for ASIL level
- Approval: Safety Manager + Technical Lead

---

### Phase 5: Implementation & Verification (8-14 days)

**Goal**: Implement design and verify correctness

**Activities**:

1. **Implementation**
   - Hardware: RTL code in Verilog/SystemVerilog
   - Firmware: C code per MISRA C:2012
   - Maintain traceability tags in code: `@requirement TSR-HW-001-001`

2. **Unit Verification (ASPICE SWE.4, HWE.4)**
   - Hardware: UVM testbench, 100% code coverage
   - Firmware: C unit tests, 100% statement + branch coverage
   - Template: unit-test-spec.md
   - Tools: VCS/Questa (HW), pytest/CUnit (FW)

3. **Integration Verification (ASPICE SWE.5, HWE.5)**
   - Test component interactions
   - Verify interfaces work correctly
   - Template: integration-test-spec.md

4. **System Verification (ASPICE SYS.4, SWE.6)**
   - Test system against all SYS-REQ
   - Qualification tests verify customer requirements
   - Template: system-test-spec.md

5. **Coverage Verification**
   - Automated traceability checking
   - ```powershell
     .\check-traceability.ps1 -Feature "001-feature-name" -Report
     .\check-requirements-coverage.ps1 -Feature "001-feature-name"
     ```
   - Target: 100% requirements covered by tests

**Key Requirement**: Zero test gaps allowed before final review
- Every SYS-REQ must have test case
- Every test must trace to requirement
- Coverage metrics required in PR

**Outputs**:
- Implementation code (RTL, C)
- unit-test-spec.md (with results)
- integration-test-spec.md (with results)
- system-test-spec.md (with results)
- Coverage reports
- Code review records

**Review Gate**: Code Review + Verification Review
- Code Review Checklist:
  - [ ] Coding standards followed (MISRA C / SystemVerilog)
  - [ ] Traceability tags present
  - [ ] Peer review completed
  - [ ] Coverage acceptable (100% statement/branch)
  - [ ] No critical static analysis violations
- Verification Review Checklist:
  - [ ] All tests passed
  - [ ] Coverage metrics acceptable
  - [ ] No orphan code
  - [ ] Requirements fully verified
  - [ ] Defects resolved

---

### Phase 6: Review & Approval (2-3 days)

**Goal**: Obtain stakeholder approval before release

**Activities**:

1. **Requirements Review** (if not already approved)
   - Review changes since initial approval
   - Verify still complete and consistent

2. **Design Review** (if not already approved)
   - Review design modifications from safety analysis
   - Verify design still addresses all requirements

3. **Final Verification Review**
   - All tests passed ✓
   - Coverage complete ✓
   - Traceability complete ✓
   - Safety analysis addressed ✓
   - All defects resolved ✓

4. **Sign-off**
   - Technical Lead approval
   - Safety Manager approval
   - Quality Manager approval
   - Project Manager approval

**Outputs**:
- Final review records (in review-records/ directory)
- Approval sign-offs documented
- All open issues resolved

---

### Phase 7: Baseline & Release (1 day)

**Goal**: Create immutable baseline and prepare for deployment

**Activities**:

1. **Version All Artifacts**
   - Freeze all documentation
   - Tag code in Git: `feature/001-v1.0`
   - Update change-log.md with final version

2. **Create Baseline**
   ```bash
   git tag -a "001-power-loss-protection-v1.0" -m "Feature 001 release"
   ```

3. **Archive for Product Lifecycle**
   - Store in controlled repository
   - Link to product version/build
   - Record for future safety audits

4. **Prepare Release Documentation**
   - Summary of changes
   - Traceability matrix (final)
   - Safety analysis (final)
   - Test results (final)

**Outputs**:
- Baselined feature directory
- Git tag for release
- Release documentation package
- Product configuration record

---

## Configuration Management Integration

### Git Workflow

**Branch Naming**:
```
feature/[ID]-[short-name]
  Example: feature/001-power-loss-protection
```

**Commit Messages** (include requirement/test ID):
```
commit: TSR-HW-001-001 - Implement power detector circuit

- Detect supply voltage drop < 1ms
- Propagation delay: 850ns (< 1ms requirement)
- Redundant comparator for fault tolerance

References: TSR-HW-001-001, TC-HW-001-001
```

**Pre-commit Hooks**:
- Verify traceability tags present in code
- Check traceability matrix updated
- Validate commit message format

**Pull Request Checks**:
- Automated traceability verification
- Coverage metric validation
- Design documentation review

---

## Quality Gates & Approval Criteria

| Gate | Criteria | Owner | Evidence |
|------|----------|-------|----------|
| **Initialization** | Scope approved, ASIL assigned | Tech Lead | Feature kickoff meeting notes |
| **Requirements** | 100% traced, stakeholder approved | Req Lead + Safety Mgr | Signed requirements review |
| **Design** | Covers all requirements, DFT planned | Arch + Tech Lead | Signed design review |
| **Safety** | FMEA/FTA complete, residual risk acceptable | Safety Mgr | Signed safety analysis review |
| **Implementation** | Code reviewed, 100% coverage, zero crit violations | Tech Lead + Peer | Signed code review |
| **Verification** | All tests pass, traceability complete | Test Lead + QA | Signed verification review |
| **Release** | All approvals obtained, baselined | PM + Safety Mgr | Feature tagged in Git |

---

## Change Management During Development

### When Requirements Change

1. **Impact Analysis**
   ```powershell
   .\check-change-impact.ps1 -File "requirements.md" -ChangeType "requirement"
   ```

2. **Update Affected Artifacts**
   - Design documents affected
   - Implementation files affected
   - Test cases affected

3. **Obtain Re-approval**
   - Requirements review (if significant change)
   - Design review (if design impact)
   - Verification review (if test impact)

4. **Update Change Log**
   - Document change with justification
   - Cross-reference impacted requirements
   - Record approvals

### When Design Changes

1. **Verify Requirements Still Satisfied**
   - Review against SYS-REQ/TSR
   - Update traceability matrix

2. **Update Implementation Plan**
   - Estimate cost/schedule impact
   - Identify blocked work items

3. **Re-execute Affected Tests**
   - Unit tests for changed modules
   - Integration tests for interfaces
   - Regression test suite

### When Implementation Changes

1. **Verify Design Specification Accuracy**
   - Code matches design documentation

2. **Update Code Traceability**
   - Add/update @requirement tags
   - Ensure full traceability

3. **Re-execute Verification**
   - Unit tests for changed functions
   - Coverage re-measurement
   - Regression testing

---

## Metrics and Reporting

### Key Metrics

**Requirements Metrics**:
- Total requirements: [count]
- Requirements by ASIL: [A/B/C/D breakdown]
- Requirements by type: [Functional/Performance/Interface]
- Requirement volatility: [% changed]

**Traceability Metrics**:
- Forward coverage: [% requirements with design/code/test]
- Backward coverage: [% code traced to requirements]
- Coverage gaps: [list of untraced items]
- Orphan items: [code/tests without requirements]

**Verification Metrics**:
- Statement coverage: [100% target]
- Branch coverage: [100% target for ASIL-B]
- Functional coverage: [% of scenarios tested]
- Defect density: [defects per KLOC]

**Schedule Metrics**:
- Planned vs. actual phase duration
- Milestone achievement rate
- Rework percentage

### Reporting

**Daily Standup** (brief):
- What got done
- What's blocked
- Next actions

**Weekly Status Report**:
- Phase progress
- Issues and risks
- Upcoming milestones

**Phase Gate Report**:
- Gate pass/fail criteria
- Evidence of compliance
- Approvals/sign-offs

---

## Best Practices

✅ **DO**:

1. **Start with requirements** - Never design without requirements review
2. **Involve safety early** - Safety Manager participates from Phase 1
3. **Automate traceability** - Use scripts to detect gaps
4. **Document decisions** - Capture "why" not just "what"
5. **Test early** - Write tests before implementation
6. **Review continuously** - Don't wait for end-of-phase reviews
7. **Version everything** - All artifacts in Git
8. **Maintain baselines** - Baseline at each phase gate

❌ **DON'T**:

1. Don't skip requirements review
2. Don't have code without traceability tags
3. Don't waive coverage goals
4. Don't skip safety analysis (FMEA/FTA/DFA)
5. Don't change requirements without impact analysis
6. Don't merge code that fails verification
7. Don't release without final review
8. Don't ignore metrics

---

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| Traceability gaps found | Requirements not flowed to TSR | Complete TSR allocation process |
| Code without traceability | Developer forgot @requirement tags | Add tags, update traceability matrix |
| Test coverage < 100% | Unreachable code or missing tests | Justify unreachable code or add tests |
| High FMEA RPN | Insufficient design mitigations | Redesign or add redundancy/monitoring |
| Changed requirements | Scope creep | Formal change control process |

---

## Tools and Environment

**Git**: Version control and branching
**Markdown**: Requirements and design documentation
**PowerShell**: Traceability automation scripts
**Coverage tools**: VCS (HW), pytest/gcov (FW)
**Static analysis**: Lint tools (Verilog), clang-analyzer (C)

---

## Next Steps

1. **Read**: [Feature Creation Guide](FEATURE-CREATION-GUIDE.md)
2. **Execute**: `.\create-feature.ps1` to create your first feature
3. **Follow**: 7-phase process outlined above
4. **Validate**: Run traceability scripts to check completeness
5. **Review**: Conduct gate reviews before proceeding

**Questions?** Contact: Process Owner, Technical Lead, or Safety Manager

---

**Document Version**: 1.0.0  
**Last Updated**: 2025-12-02  
**Next Review**: 2026-03-02
