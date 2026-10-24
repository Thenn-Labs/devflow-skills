# Reports

> Any agent may **append** a report when another agent misbehaves or something goes wrong (broken build, overwritten work, rule broken, data lost…).
> The **main agent** investigates, writes a decision, and tells the user about serious cases.
> Created: {{DATE}}

## Format

```markdown
## R-000: <short title>
- **Reported by:** <agent> on YYYY-MM-DD HH:MM
- **About:** <agent name / "system">
- **What happened:** <facts only>
- **Evidence:** <commits, files, lines, logs>
- **Impact:** <what broke or is at risk>
- **Status:** OPEN | DECIDED
- **Main agent decision:** <action taken, e.g. warning, task reassigned, permissions reduced in role.md, user informed>
```

## Reports
<!-- New reports below this line. -->
