---
name: devflow-setup
description: Devflow workspace rules for any project. Use at the start of every session in a project (or when the user types /devflow-setup) to identify whether this is the main session or a child agent, set up the workspace files (CLAUDE.md, context.md, progress.md, agents.md, AgentQuestions.md, AgentAnswers.md, role.md, tasks.md, report.md), and follow the user's git, branching, questioning, logging, cleanup and multi-agent rules for all later work.
---

# Devflow: Workspace Rules

These rules apply to every project where this skill is used. They stay in force for the whole session, not just the first reply.

## Core rules (always on)

1. **Protected branches.** `main`, `master`, `staging` (and `production`, `prod`, `release` if they exist) are protected. Never commit, push or merge into them on your own.
2. **Branch per feature.** Every new feature, fix or change gets its own branch. Merge into `staging`/`main` **only when the user explicitly says so** for that change. Even then, first confirm that both `main` and `staging` exist and are set up properly (exist locally and on the remote, tracking is correct, they're in sync with the remote). If they aren't, stop and tell the user. Don't create or "fix" them on your own.
3. **Work in a refined, proper way.** Read the existing code before changing it. Follow the project's conventions. Make small, focused changes, verify each one, and leave no half-done work.
4. **Never assume. Ask.** If anything is unclear (requirements, naming, design, data, behaviour, priorities, credentials), ask the user. You can ask as many questions as you need. Group them and use `AskUserQuestion` where it fits. Look up facts in the code yourself, but ask the user about intent and decisions. Never invent requirements, sample data, API keys, or business rules.
5. **Every change is explainable.** For every change, you must be able to say what changed, why, which files, and how it was verified. Write this into `progress.md` (format below) and into the commit message.
6. **No leftovers.** Temporary files, scratch scripts, test data, debug logs, test accounts and load-test scripts are removed once they've been used. Put temporary work in the session scratchpad directory, not in the project. Before finishing, run `git status` and check that nothing stray is left.
7. **Get better every time.** Every task, bug and correction should leave the system more stable and you better informed. See "Getting better" below.

## Step 1: Identify the session (always first)

Before doing anything else, ask the user:

- **"Who are you, and is this the main session (main Claude / main agent) or a child session?"**
- If it's a **child session**, also ask what name this agent should use (suggest one, e.g. `agent-frontend`), unless the user already gave one.

Don't guess the answer from context. Wait for it.

Then introduce yourself in one line: **agent name, model (exact model name/ID you are running on), and session type.**
Example: `I am agent-frontend, running Claude Opus 5.5 (claude-opus-5-5), child session.`

## Step 2: Inspect the project

Run read-only checks and report the results briefly:

- `git rev-parse --is-inside-work-tree`. If this isn't a git repo, ask the user whether to run `git init`. Don't do it on your own.
- `git status`, `git branch -a`, `git remote -v`, `git log --oneline -30`
- Whether `main` and `staging` exist locally and on the remote. Record this in `context.md` under Environments.
- Which workspace files already exist.

## Step 3: Set up the workspace files (fresh start)

Run the bootstrap script. It creates only the files that are missing and never overwrites existing ones. If `CLAUDE.md` already exists, the script appends the workspace section to it once.

```bash
bash "<this skill's base directory>/scripts/init-workspace.sh" "<project root>"
```

| File | Purpose | Who writes |
|---|---|---|
| `CLAUDE.md` | Project rules plus **Lessons learned**. Loaded by Claude every session. | Main (child agents may suggest lessons) |
| `context.md` | Full context of the project | Main; child agents add facts they discover |
| `progress.md` | Full history of changes plus a log of every new change | Everyone (append only) |
| `agents.md` | Agent rules plus the registry of agents | Main writes the rules; each agent edits only its own registry row and log lines |
| `AgentQuestions.md` | Questions from agents | Agents append; main sets the status |
| `AgentAnswers.md` | Every question with its answer | Main |
| `role.md` | Each agent's role and permissions | Main only |
| `tasks.md` | Tasks given to agents (one-off and daily) | Main assigns; an agent updates only the status and notes of its own tasks |
| `report.md` | Reports about agent misbehaviour or incidents | Anyone reports; main decides |

After running the script, the **main session** must also:

1. **Fill in `context.md`** by reading the codebase: purpose, stack, architecture, folder map, how to run/build/test, environments, integrations, names of the environment variables (never their values), conventions, and known issues. Mark anything you can't find as `UNKNOWN: ask user` and then ask the user.
2. **Fill in `progress.md` history.** If git history or older notes exist, rebuild a "History" section from `git log` (grouped by date or feature, with the commit hashes). If there's no history, leave the section empty. From now on, every change gets an entry.
3. **Review `agents.md` rules** with the user. The template has default rules. Change them only if the user asks.

A **child session** doesn't run the setup. It reads the files and registers itself (see the multi-agent section). If the files don't exist yet, it tells the user that the main session must set up the workspace first.

Show the user the list of files you created or skipped, then continue with the actual project work.

## Step 4: Git workflow

- Before starting work, check which branch you're on. If it's a protected branch, create a new branch first.
- Branch names: `feature/<short-name>`, `fix/<short-name>`, `chore/<short-name>`, `client/<date>-<short-name>`. In multi-agent work, prefix the branch with the agent name: `agent-frontend/feature/login`.
- Base branch: `staging` if it exists, otherwise `main`. If that's unclear, ask.
- Commit in small, logical steps. A commit message says **what** and **why**.
- Ask before the first push of a branch to the remote.
- Never: force-push, rebase or rewrite shared history, delete branches, change the remote, or skip hooks (`--no-verify`), unless the user explicitly asks.
- **Merging into staging/main happens only when the user says so.** When they do:
  1. Check that both `main` and `staging` exist and are set up properly (see core rule 2). If not, stop and report.
  2. Make sure the branch is up to date and its tests pass.
  3. Merge into `staging` first. Merge into `main` only if the user said main.
  4. Log the merge in `progress.md`.

## Step 5: While working

- Before coding, restate the task in a few lines and list any open questions. Ask them before you build.
- Read the related code before you edit it, and reuse what already exists.
- Verify every change: run it, test it, or open it in the browser (use the `/devflow-test` skill for deeper checks).
- After each meaningful change, add a `progress.md` entry:

```markdown
### YYYY-MM-DD: <short title>
- **Agent:** <name> (<model>)
- **Branch:** <branch>
- **What:** <what changed>
- **Why:** <reason / request it came from>
- **Files:** <paths>
- **Verified:** <how it was tested, result>
- **Open / follow-ups:** <anything left, or "none">
```

- If you find something new about the project, update `context.md`.
- Clean up temporary things right after you use them (core rule 6).

## Step 6: Multi-agent protocol

Files are the shared channel between agents. Always re-read a file right before editing it, edit only your own sections, and append rather than rewrite, because other agents may be editing too.

### Main agent duties
- Writes and maintains the rules in `agents.md`.
- On every start, and between tasks, checks:
  - `AgentQuestions.md` for `OPEN` questions. Answer **every** question while online. Write the question and answer into `AgentAnswers.md`, then set the question to `ANSWERED`. If the main agent can't answer, it asks the user, and never guesses for the agent.
  - `report.md` for `OPEN` reports. Investigate, decide, write down the decision (for example warn, reassign, or reduce permissions in `role.md`), and tell the user about serious ones.
  - `tasks.md` for `BLOCKED` and `REVIEW` items.
- Gives roles in `role.md`, always with written permissions.
- Assigns one-off or daily tasks in `tasks.md`. Gives each agent separate files or areas so agents don't edit the same files at once.
- Reviews child agents' branches before the user is asked to merge anything.

### Child agent duties
- On coming online:
  1. State your name and model, then add or update your row in the `agents.md` registry (status `online`) and add a log line.
  2. Read `CLAUDE.md`, `context.md`, the latest `progress.md` entries, your entry in `role.md`, your tasks in `tasks.md`, and new answers for you in `AgentAnswers.md`.
  3. Check `tasks.md` for changes since you were last online.
- Work only within your role's permissions, on your own branch.
- When in doubt, add a question to `AgentQuestions.md` (format in the file). While you wait, work on something that doesn't depend on the answer, or mark the task `BLOCKED (Q-xxx)`.
- Update the status of your own tasks in `tasks.md`.
- If another agent breaks rules, damages work or causes a problem, report it in `report.md` with evidence.
- Before going offline, update your task statuses, set your registry status to `offline`, and add a log line.

## Step 7: Before finishing any task

- [ ] Work is on a feature branch, and nothing was pushed or merged to protected branches without the user's instruction
- [ ] The change is verified, and you can explain it
- [ ] `progress.md` entry written, and `context.md` updated if needed
- [ ] Temporary files and test data removed, and `git status` is clean apart from the intended changes
- [ ] Lessons added (below)
- [ ] Final message to the user: what was done, how it was verified, what's left, and any questions

## Getting better (core rule 7)

`CLAUDE.md` has a **Lessons learned** section that Claude reads at the start of every session. Add one short line there whenever:
- the user corrects you or tells you a preference
- a bug turns out to come from a pattern that could happen again
- a command, setup step or workaround took effort to figure out
- a test finds a weak spot

Format: `- YYYY-MM-DD: <lesson as a rule to follow>`. Keep lessons short, merge duplicates, and remove ones that are outdated.

Also: every fixed bug should get a regression test where possible, so the same bug can't come back.
