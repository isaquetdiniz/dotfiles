# CLAUDE.md

Preferences and best practices that apply across all projects.

## Context Engineering (Main Agent Discipline)

The main agent is an **orchestrator**, not a worker.

**Main agent role:** Coordinate files, spawn sub-agents, process
summaries, communicate with the user.

**Main agent NEVER:** Explores the codebase broadly, implements code
changes, runs builds/tests, processes large command output.
All of these get delegated to sub-agents.

### Sub-agent Communication Protocol

- Every prompt ends with: "Return a structured summary: [exact fields]"
- Never ask a sub-agent to "return everything"
- Target 10-20 lines of actionable info per result
- Chain sub-agents: pass only relevant fields between them

## Model Assignment Matrix
| Task Type | Model |
|---|---|
| File scanning, discovery, dependency analysis | haiku |
| Simple fixes (lint, format, typos, CSS)	| haiku |
| Documentation updates	| haiku / sonnet |
| Standard implementation | sonnet |
| Bug investigation & root cause analysis	| sonnet |
| Test writing	| sonnet |
| Complex multi-file refactoring | opus |
| Architectural decisions | opus |
| Merge conflict resolution	| opus |
