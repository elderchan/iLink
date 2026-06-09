# ilink-lightme

Run the iLink Lightme (design interrogator) role — an optional advisory step between `/ilink-design` and `/ilink-approve`.

## Usage

```
/ilink-lightme <story>
```

## Prerequisites

**IMPORTANT**: Lightme MUST run in a **brand-new Qoder session**, cannot follow `/ilink-design` in the same session (same-model bias, see Root Spec §4.8.5).

The bash script `.qoder/commands/ilink-lightme <story>` has already validated design.master.md existence, computed Upstream_SHA1, and reported domain coverage. Now proceed with the interrogation task.

## Preparation

- Read `iLink/souls/universal.soul.md` and its plug (if exists)
- Read `iLink/souls/lightme.soul.md` and `iLink/souls/plugs/lightme.project.plug.md` (if exists)

## Pre-check

- Read `iLink-doc/<story>/<story>-design.master.md`
- If not exists, tell user to run `/ilink-design <story>` first and stop
- Check design.master.md Status:
  - `STAGING` (typical) → proceed
  - `PENDING_CODER` → **refuse execution**: design already approved, lightme is pointless. Tell user: either re-run `/ilink-design` then lightme, or manually review and leave notes
  - Other status → warn but proceed

### Order advice with /ilink-refine

If design has `[待确认]` items, **recommend running `/ilink-refine` first** to resolve known uncertainties, then `/ilink-lightme` to discover unknown blind spots. Rationale: refine resolves "known unknowns", lightme uncovers "unknown unknowns" — resolve knowns first to avoid lightme redundantly probing already-flagged areas.

Order is not mandatory; Leader may also run lightme first to surface all issues simultaneously.

## Execution (interrogation main flow)

Follow lightme.soul.md section 3 "work method": four principles + code-reading + terminology interrogation + scenario stress-testing + code cross-validation.

Follow lightme.soul.md section 5 for follow-up strategy: dynamic-driven + high-frequency dimension scanning (no filler questions).

Follow lightme.soul.md section 4 for retrieval limitation annotations: positive/negative conclusion distinction.

Each identified blind spot → annotate with tri-state (RESOLVED / TO-FIX / ACCEPTED-RISK) → append to `<story>-lightme.md` "illuminated blind spots and dispositions" section.

## Three-type md write boundaries

Follow lightme.soul.md section 6:
- Write `project-context.md` — MUST Human-Gate confirm before writing, SHALL NOT touch §7.8 isolation blocks
- Write existing `<module>-domain-knowledge.md` — MUST Human-Gate confirm before writing
- **domain-knowledge.md §10 待确认区块 SHALL NOT be modified by lightme**; if clarification should go into §10, write into report's "建议补充 domain" section and hand off to `/ilink-domain` (see Root Spec §4.8.10)
- If domain-knowledge.md does not exist — SHALL NOT create; write into report's "建议补充 domain" section

## Output

`iLink-doc/<story>/<story>-lightme.md`, per Root Spec §4.8.12 structure.

## Metadata stamp

```
---
# ILINK-PROTOCOL-METADATA
Protocol_Version: v1.8.0
Role: LIGHTME
AI_Vendor: Qoder
AI_Model: <actual version>
Current_Timestamp: <shell-obtained>
Upstream_SHA1: <shasum design.master.md first column>
Status: ADVISORY
---
```

SHA1 and Timestamp MUST be obtained via shell commands. The pre-check script (`.qoder/commands/ilink-lightme`) has already computed SHA1 and printed it to terminal — you may use that value directly.

## After completion

- Tell user: lightme.md has been generated, recommend reviewing before approve
- TO-FIX blind spots → suggest going back to `/ilink-design` (or `/ilink-refine`) to fix
- ACCEPTED-RISK blind spots → documented, approve means accepting these risks
- No pass/fail verdict

## Hard constraints (anti-rubber-stamp)

- SHALL NOT produce "pass", "can proceed to coding", "design is fine", "recommend approval" language
- MUST identify at least 3 specific, evidence-based blind spots (unless Leader confirms full coverage)
