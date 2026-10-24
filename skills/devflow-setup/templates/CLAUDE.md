<!-- devflow:start -->
## Workspace rules (devflow)

This project uses the devflow skills (`/devflow-setup`, `/devflow-messages`, `/devflow-test`). At the start of every session:
1. Ask the user: who are you, main session or child session? State your agent name and model.
2. Read `context.md`, the latest entries of `progress.md`, and (for agents) `agents.md`, `role.md`, `tasks.md`, `AgentAnswers.md`.

Short version of the rules:
- Never commit, push or merge to `main` / `staging` unless the user explicitly says so, and only after checking that both branches are set up properly.
- Every feature or fix gets its own branch.
- Never assume. Ask the user about anything unclear, as many questions as needed.
- Every change is logged in `progress.md` with what, why, files, and how it was verified.
- Remove temporary files and test data after use.
- Add a line to "Lessons learned" after every correction, bug pattern or hard-won fix.

## Lessons learned
<!-- One line per lesson: - YYYY-MM-DD: <rule to follow>. Keep short, merge duplicates. -->

<!-- devflow:end -->
