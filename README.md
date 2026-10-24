# devflow-skills

Workflow skills for AI coding agents (built for Claude Code; also usable with other agents through the [Skills CLI](https://skills.sh)). They make an agent work like a careful teammate: safe git branching, asking instead of assuming, logging every change, coordinating multiple agents through shared files, handling client feedback, and doing real QA and security testing.

| Command | What it does |
|---|---|
| `/devflow-setup` | Run at the start of a session. Asks whether this is the main or a child session, sets up the workspace files, and applies the rules for the whole session. |
| `/devflow-messages` | Paste a client's messages. The agent breaks them into a list of changes, asks about anything unclear, implements them on a branch, and drafts a reply for the client. |
| `/devflow-test` | Full QA and security testing: browser or phone testing, many input tries per field, security audit, performance, stress, and recovery testing. Every finding is checked before it's reported, then bugs are listed by severity and fixed. |

## Install

**Option A: Skills CLI (Claude Code, Cursor, Codex and others)**

```bash
npx skills add Thenn-Labs/devflow-skills --global
```

**Option B: Claude Code plugin**

```
/plugin marketplace add Thenn-Labs/devflow-skills
/plugin install devflow@devflow-skills
```

Commands are then namespaced, e.g. `/devflow:devflow-setup`.

**Option C: clone and link (for editing the skills yourself)**

```bash
git clone https://github.com/Thenn-Labs/devflow-skills.git
cd devflow-skills
for s in skills/*/; do ln -s "$PWD/$s" ~/.claude/skills/; done
```

**Recommended companion** for deep security audits:

```bash
npx skills add https://github.com/cloudflare/security-audit-skill --skill security-audit --global
```

Restart your agent after installing.

## The rules (`/devflow-setup`)

1. Never commit, push or merge to `main` / `staging` unless the user says so, and only after checking both branches are set up properly.
2. Every feature or fix gets its own branch.
3. Work carefully: read before editing, follow project conventions, verify every change.
4. Never assume. Ask as many questions as needed.
5. Every change is explainable and logged in `progress.md`.
6. Temporary files and test data are removed after use.
7. Get better every session: lessons go into `CLAUDE.md`, and every fixed bug gets a regression test.

### Workspace files it creates

| File | Purpose |
|---|---|
| `CLAUDE.md` | Project rules plus "Lessons learned" |
| `context.md` | Full project context |
| `progress.md` | History plus a log of every change |
| `agents.md` | Agent rules and the registry (name, model, status) |
| `AgentQuestions.md` | Questions from child agents |
| `AgentAnswers.md` | Questions with the main agent's answers |
| `role.md` | Each agent's role and permissions |
| `tasks.md` | Tasks assigned to agents (one-off and daily) |
| `report.md` | Reports about agent misbehaviour or incidents, decided by the main agent |

Existing files are never overwritten. If `CLAUDE.md` exists, the devflow section is appended once.

### Main and child agents

Run several agent sessions on one project. The **main** session sets up the files, assigns roles and tasks, answers questions and decides on reports. **Child** sessions introduce themselves (name and model), register in `agents.md`, check `tasks.md` when they come online, ask in `AgentQuestions.md` instead of guessing, and work only on their own branches.

## Security testing

`/devflow-test` includes a security method (`skills/devflow-test/SECURITY.md`) adapted from Cloudflare's [security-audit-skill](https://github.com/cloudflare/security-audit-skill):

- A finding needs a real **boundary and result**: who the attacker is, what they send, which control fails, and what damage follows. Missing best practices are reported separately as hardening notes.
- Every finding gets one verdict: **confirmed** (with severity), **needs validation** (depends on config outside the code), or **rejected**.
- Covers the core attack classes, an "obvious things" checklist, and sections for web/auth, client-side, AI/LLM, webhooks, cost/DoS, multi-tenant data, mobile, cloud config and CI supply chain.
- Stress and attack tests run only on local or staging unless the user explicitly allows otherwise.

## Repository layout

```
skills/
  devflow-setup/      SKILL.md, templates/ (the workspace files), scripts/init-workspace.sh
  devflow-messages/   SKILL.md
  devflow-test/       SKILL.md, SECURITY.md
.claude-plugin/       plugin.json, marketplace.json (Claude Code plugin install)
```

## Contributing

Open an issue or pull request. Keep changes on a branch, and explain what changed and why.

## License

MIT. See [LICENSE](LICENSE). Parts of `SECURITY.md` are adapted from Cloudflare's MIT-licensed security-audit-skill; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
