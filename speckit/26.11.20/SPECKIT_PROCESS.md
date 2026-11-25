# Spec Kit Process for Agile611 Koinos RISC-V

This document outlines the Spec Kit workflow for the Agile611 Koinos RISC-V Linux distribution project.

---

## Overview

Spec Kit provides a structured, agent-driven approach to specification-driven development. Each command/skill builds upon the previous one to ensure clarity, consistency, and traceability from requirements to implementation.

---

## Workflow Steps

### 1. `/speckit-constitution` — Set Core Principles
**Purpose**: Establish immutable engineering, testing, and architectural principles.

**Output**: `constitution.md` — The project's constitutional document defining:
- Architectural pillars (CPU, Kernel, Boot, Embedded fallback)
- Hardware tier classifications
- Device Tree sources and build pipeline
- Engineering standards
- Testing & validation checklists
- Git discipline & commit protocol
- Environment & tooling standards
- Anti-loop guard & recovery procedures

---

### 2. `/speckit-specify` — Write What to Build and Why
**Purpose**: Create a clear, unambiguous specification of the desired system.

**Output**: `spec.md` — Contains:
- Problem statement & goals
- User stories / use cases
- Functional requirements
- Non-functional requirements (performance, security, compatibility)
- Acceptance criteria
- Scope boundaries (in/out of scope)

---

### 3. `/speckit-clarify` — Resolve Ambiguities Before Planning
**Purpose**: Identify and resolve open questions, edge cases, and assumptions.

**Output**: `clarifications.md` — Documents:
- Open questions with resolutions
- Assumptions made
- Dependencies identified
- Risk mitigations
- Stakeholder decisions

---

### 4. `/speckit-plan` — Define Architecture, Tech Stack, and Design Artifacts
**Purpose**: Translate specifications into concrete technical architecture.

**Output**: `plan.md` — Includes:
- System architecture diagram (components, interfaces, data flows)
- Technology stack decisions (kernel version, toolchain, base distro)
- Module/component breakdown
- Interface contracts (APIs, Device Tree bindings, boot protocols)
- Data models (partition layout, memory maps)
- Security model
- Deployment architecture (image types, update mechanisms)

---

### 5. `/speckit-checklist` & `/speckit-tasks` — Generate Requirement Checks and Ordered Tasks
**Purpose**: Create verifiable acceptance criteria and an executable task list.

**Outputs**:
- `checklist.md` — Traceable requirement verification matrix
  - Each requirement → test/validation method → pass/fail criteria
- `tasks.md` — Ordered, dependency-aware task breakdown
  - Task ID, description, dependencies, acceptance criteria
  - Estimated effort, assigned owner
  - Milestone grouping

---

### 6. `/speckit-analyze` & `/speckit-implement` — Check Consistency and Execute
**Purpose**: Validate artifacts against each other and implement the solution.

**`/speckit-analyze`** — Cross-artifact consistency checks:
- Constitution ↔ Spec alignment
- Spec ↔ Plan coverage
- Plan ↔ Tasks completeness
- Checklist ↔ Tasks traceability

**`/speckit-implement`** — Execute tasks with validation:
- Run tasks in dependency order
- Verify each task against checklist criteria
- Update task status (pending → in_progress → done/blocked)
- Generate implementation artifacts (code, configs, scripts, docs)
- Run validation suites (dtbs_check, QEMU boot, kernel config)

---

## Artifact Traceability Matrix

| Artifact | Produced By | Consumed By | Validates |
|----------|-------------|-------------|-----------|
| `constitution.md` | `/speckit-constitution` | All subsequent steps | Architectural compliance |
| `spec.md` | `/speckit-specify` | `/speckit-clarify`, `/speckit-plan` | Requirements completeness |
| `clarifications.md` | `/speckit-clarify` | `/speckit-plan` | Ambiguity resolution |
| `plan.md` | `/speckit-plan` | `/speckit-checklist`, `/speckit-tasks` | Technical feasibility |
| `checklist.md` | `/speckit-checklist` | `/speckit-analyze`, `/speckit-implement` | Acceptance criteria |
| `tasks.md` | `/speckit-tasks` | `/speckit-implement` | Execution order & dependencies |

---

## Execution Guidelines

### Agent Invocation
```bash
# Launch preferred coding agent in project directory
# Run Spec Kit commands sequentially:
/speckit-constitution
/speckit-specify
/speckit-clarify
/speckit-plan
/speckit-checklist
/speckit-tasks
/speckit-analyze
/speckit-implement
```

### Quality Gates
- **After Constitution**: All team members acknowledge principles
- **After Specify**: Stakeholder sign-off on requirements
- **After Clarify**: Zero unresolved blocking ambiguities
- **After Plan**: Architecture review passed
- **After Checklist/Tasks**: Traceability matrix 100% covered
- **After Analyze**: Zero cross-artifact inconsistencies
- **After Implement**: All checklist items verified, CI green

---

## Agile611 Koinos RISC-V-Specific Adaptations

Given the RISC-V distribution nature of Agile611 Koinos RISC-V, the following adaptations apply:

| Standard Spec Kit | Agile611 Koinos RISC-V Adaptation |
|-------------------|------------------|
| Unit tests | Kernel config validation (`make dtbs_check`), QEMU boot smoke tests |
| Integration tests | Multi-board DTB validation, UEFI/extlinux boot verification |
| Deployment | `mmdebstrap` rootfs generation, image building, firmware packaging |
| Performance | Boot time, memory footprint, RVV acceleration benchmarks |
| Security | SBOM generation, reproducible builds, secure boot chain validation |

---

## References

- [Agile611 Koinos RISC-V Constitution](./constitution.md) — Core principles
- [Spec Kit Documentation](https://github.com/github/spec-kit) — Upstream methodology
- [RISC-V Distribution Architecture Guide](./KoinV_Initial_Requeriments.pdf) — Source requirements

---

*Generated: 2026-11-20*
*Part of Agile611 Koinos RISC-V Distribution Project*
