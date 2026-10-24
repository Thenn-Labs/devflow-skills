# Agents

> Owned by the **main agent**. Child agents may only edit **their own row** in the Registry and **add lines** to the Log.
> Created: {{DATE}}

## Rules for every agent

1. **Introduce yourself** when you come online: agent name, exact model, session type (main/child). Add or update your Registry row and add a Log line.
2. **Read before working:** `CLAUDE.md`, `context.md`, latest `progress.md` entries, your entry in `role.md`, your tasks in `tasks.md`, and answers for you in `AgentAnswers.md`.
3. **Check `tasks.md`** for changes every time you come online.
4. **Stay inside your role.** Only touch the files and actions your permissions in `role.md` allow.
5. **Own branch only.** Name it `<agent-name>/<type>/<short-name>`. Never commit, push or merge to `main` / `staging`.
6. **Never guess.** Put doubts in `AgentQuestions.md`. You may ask as many questions as you need.
7. **The main agent answers every question** whenever it is online, in `AgentAnswers.md`.
8. **Log every change** in `progress.md`.
9. **Clean up** temporary files and test data after use.
10. **Report problems.** If an agent misbehaves or something goes wrong, write it in `report.md` with evidence. The main agent decides what happens.
11. **Before going offline:** update your task statuses, set your Registry status to `offline`, and add a Log line.
12. **Shared files:** re-read a file right before editing it and append instead of rewriting, because other agents may be editing too.

## Registry

| Agent name | Model | Type | Role | Status | Branch | Last seen |
|---|---|---|---|---|---|---|

## Log
<!-- - YYYY-MM-DD HH:MM: <agent>: <message> (e.g. "online", "took T-003", "offline") -->
