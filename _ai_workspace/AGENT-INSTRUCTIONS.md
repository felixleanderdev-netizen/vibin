# AI Agent Instructions - Important

## ⚠️ CRITICAL: Never Include Time Estimates

**DO NOT** include:
- Hours, days, weeks, months
- "Estimated" durations
- "Effort" levels (Low, Medium, High - with time implications)
- "Time saved" comparisons
- "Ahead/behind schedule" statements
- Any temporal language suggesting duration

**WHY**: Time estimates are unreliable and misleading. Task complexity and actual time needed vary significantly based on unknown factors. Providing estimates creates false expectations.

---

## What To Include Instead

✅ **DO Include**:
- Clear task descriptions
- What's being built (deliverables)
- Dependencies between tasks
- Complexity level (conceptual, not time-based)
- Risks and constraints
- Technical details and requirements

✅ **Example Format**:
```
### Task Name
**Assignee**: AI Agent  
**Dependencies**: Task X, Task Y  
**Priority**: High

**Description**: What this task does...

**Deliverables**:
- [ ] Item A
- [ ] Item B
- [ ] Item C

**Success Criteria**:
- Builds without errors
- Meets specifications in docs/...
```

---

## Applied To

This policy has been applied to:
- [ ] `_ai_workspace/phase-1.md` ✅
- [ ] `_ai_workspace/index.md` ✅
- [ ] `_ai_workspace/task-1.2-completion.md` ✅
- [ ] `mobile/TASK-1.2-README.md` ✅

All existing time estimates have been **removed**. Do not restore them.

---

## For Future Workflow

When updating task boards, progress files, or documentation:

1. **Remove** any time/duration language
2. **Replace** with clear deliverables + success criteria
3. **Focus** on what was built, not how long it took
4. **Reference** docs/roadmaps for architecture + scope (not schedule)

## Self-Verification Requirement

After each task completion, verify the AI workspace state:
- Ensure generated files are present in `_ai_workspace/` and relevant project paths
- Confirm update of task status via `manage_todo_list`
- Validate backend/mobile code compiles (e.g., `dotnet build`, `flutter analyze` when possible)
- Create/append completion note in `_ai_workspace/task-<n>.completion.md`

---

**Last Updated**: 2026-03-30  
**Added By**: GitHub Copilot (Claude Haiku 4.5)

> NOTE: Testing will not be implemented in this project.
