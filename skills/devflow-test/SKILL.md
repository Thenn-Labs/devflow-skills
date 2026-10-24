---
name: devflow-test
description: Full testing, QA and security audit of a project by the main or any child agent. Use when the user types /devflow-test or asks to test, QA, audit, security-check, pen-test the code, stress-test or find bugs in an app, website or API. Tests in the real browser or on the user's phone when possible, otherwise does a full code audit. Covers input testing with many tries, security (trust boundaries, access control, injection, rate limiting, bot protection, secrets, supply chain), performance, stress/load, recovery and regression testing. Tries to disprove every finding before reporting it, lists the verified bugs by severity, then fixes them.
---

# Devflow: Testing & Security Audit

All `/devflow-setup` rules apply (branch for fixes, never assume, log in `progress.md`, clean up after).

The security part follows the method in [SECURITY.md](SECURITY.md), which is adapted from Cloudflare's security-audit skill. Read it before Step 2C.

## Step 0: Scope and safety (ask if unclear)

Confirm with the user before testing:
- **What** to test: the whole app, or specific features, pages or endpoints.
- **Where:** local, staging, or production.
  - Stress, load, fuzzing and attack payloads run **only on local or staging**.
  - Never run them against production, a client's live site, shared infrastructure, or third-party APIs (payments, email, SMS, maps, paid AI) unless the user explicitly allows it. They can cost money, send real messages, harm real users, or get accounts blocked.
  - On production, only normal-use checks (read-only browsing, a test account doing ordinary actions) with the user's okay.
- **Test accounts and data:** use dummy users, dummy records and fake secrets. Never use real customer data. Never invent credentials, so ask for them.
- **Code you don't trust** (a third-party repo, a client's unknown codebase): read it, but don't build or run it outside an isolated sandbox (no network, no real secrets, resource limits). If no sandbox is available, audit the source only and mark runtime questions as "needs validation".

## Step 1: Choose how to test

Use the best method that's available, in this order:

1. **Website / web app → real browser.** Load the `claude-in-chrome` skill (or the built-in browser) and actually use the site: click through the flows, fill in forms, and watch the console and network for errors. Check the layout at phone width (~375px).
2. **Mobile app → the user's phone.** Ask the user to connect their phone (Android: USB debugging + `adb devices`; Expo: Expo Go on the same Wi-Fi; a website on the phone: open `http://<computer-LAN-IP>:<port>`). Guide them step by step, and read logs (`adb logcat`, Metro logs) while they test.
3. **Neither is possible → full code audit.** Read the code for every item in the checklist and trace each case through the source.

**Always do the code audit as well**, even after browser or phone testing, because most security problems can't be seen from the UI.

## Step 1b: Map the system first (5–10 minutes, before testing)

Write a short map (keep it in the scratchpad, and put lasting facts in `context.md`):
- **Entry points:** pages, API routes, webhooks, cron jobs, queue consumers, file uploads, CLI commands, admin panels
- **Who can call each one:** anonymous, logged-in user, admin, another service, a webhook sender
- **Trust boundaries:** where lower-trust input reaches higher-trust code or data (user → server, user A → user B's data, tenant → tenant, user → admin, app → database/shell/filesystem/AI model)
- **Valuable things:** accounts, money and payments, personal data, files, admin actions, API keys, paid quotas
- **Existing protections:** auth middleware, validation library, rate limiter, CSRF, CORS, bot protection, security headers
- **Domains present:** web/auth, client-side, AI/LLM, mobile/desktop, cloud/deploy config, queues/webhooks, multi-tenant data, CI/release. These pick which extra sections of [SECURITY.md](SECURITY.md) apply.

## Step 2: Test checklist

Go through every area that applies. Record what you tested and the result, and never mark something "passed" without checking it.

### A. Functional
- Every page, screen, button, link and API endpoint works on the happy path
- Navigation, back button, refresh mid-flow, deep links
- Error, empty and loading states appear correctly
- Login / logout / session expiry flows

### B. Input testing (every input, many tries each)
For every form field, query parameter, header, API body and file upload, try:
- empty, only spaces, leading/trailing spaces
- minimum length, maximum length, max + 1, very long (10,000+ characters)
- special characters `' " ; -- < > & % \ /`, emoji 😀, Unicode/RTL text (हिंदी, العربية), null byte
- wrong type (text in a number field, array instead of string, object instead of number), negative numbers, 0, decimals, huge numbers
- invalid formats: email, phone, date (31 Feb, year 0001/9999), URL
- injection payloads: SQL `' OR '1'='1`, NoSQL `{"$gt":""}`, XSS `<script>alert(1)</script>` and `"><img src=x onerror=alert(1)>`, template `{{7*7}}`, command `; ls`, path traversal `../../etc/passwd`
- extra or unexpected fields in the request body (`"role":"admin"`, `"userId":<other id>`, `"price":0`)
- double-click / double-submit, the same request sent twice, pasting, autofill
- file upload: wrong type, renamed extension, 0 bytes, very large file, malicious filename, zip bomb, SVG with script
- Check that validation happens **on the server**, not only in the browser. Call the API directly the way the UI never would.

### C. Security
Follow [SECURITY.md](SECURITY.md): the core attack classes, the "obvious things" checklist, and the extra sections for each domain found in Step 1b. Always cover at least:
- **Access control:** can user A read or change user B's data by changing an ID? Admin routes protected on the server? Bulk, export and import endpoints check each item?
- **Rate limiting** on login, signup, OTP, password reset, contact forms, search, AI calls and any expensive or paid action, keyed so one user can't bypass it (not only by a spoofable IP header).
- **Bot protection** on public forms (captcha, honeypot, bot detection), and what happens with scripted requests.
- **Secrets & config:** nothing in the repo, git history, client bundle or logs. Debug mode off in production.
- **Dependencies:** `npm audit` / `pnpm audit` / `pip-audit` / equivalent, plus lockfile present.

### D. Performance
- Page load and Core Web Vitals (Lighthouse or browser performance tools), bundle size, image sizes
- API response times (note typical and slowest), slow DB queries, N+1 queries, missing indexes
- Memory use over time, unnecessary re-renders or repeated requests

### E. Stress / load (local or staging only)
- Before load-testing, check the code for **cost amplifiers**: one small request causing huge work (unbounded pagination, deep nested queries, regex backtracking, decompression, fan-out to paid APIs). These are often worse than raw volume.
- Use a load tool (`autocannon`, `k6`, `hey`, `ab`). Run it with `npx` or install it in the scratchpad, never into the project's dependencies.
- Ramp up step by step (e.g. 10 → 50 → 100 → 500 concurrent) and record response times, error rate, and CPU/memory at each step. Stop at the first clear failure.
- Find the breaking point and what fails first (DB connections, memory, timeouts, rate limiter, worker pool).
- Concurrency: two tabs or users editing the same thing, race conditions (double spending, duplicate orders, coupon reuse).

### F. Recovery
- Server restart or crash mid-request: does data stay consistent? Do partial writes get rolled back (transactions)?
- Database or external API down or slow: proper error, no fail-open (e.g. auth check skipped when its service is down), recovery when it comes back
- Network offline / slow (browser throttling): retries with limits, no duplicate submissions, idempotency
- Invalid or expired session, corrupted local storage, cleared cookies
- Backups and restore, if the project has them. Restore must not bring back deleted users' access.

### G. Compatibility & accessibility (for UI)
- Phone, tablet and desktop widths; Chrome, Firefox and Safari if available
- Keyboard navigation, visible focus, labels on inputs, readable contrast

### H. Regression
- Run the existing test suite. After fixes, re-run everything that was affected.

## Step 3: Verify every finding (try to disprove it)

A finding isn't a bug until it survives an honest attempt to prove it wrong.

For each candidate:
1. Trace the full path from the input to the harmful result in the source, and check every protection along the way (middleware, validation, framework defaults, DB constraints, upstream limits).
2. For security candidates, state the boundary (see [SECURITY.md](SECURITY.md)): who the attacker is, what they send, which control should stop it, what they gain, and whose data or resource is affected. If you can't name a real victim or damage, it's a hardening note, not a vulnerability.
3. Reproduce it with the smallest safe local check you can (a unit test, a curl against localhost, a dummy account), and stop at the first proof.
4. For important findings (Critical/High) in larger audits, ask a **separate subagent** that didn't find it to try to disprove it from the source.
5. Give each candidate one verdict:
   - **Confirmed:** proven path and result. Gets a severity.
   - **Needs validation:** depends on a fact outside the code (hosting config, CDN, proxy, provider settings). Write the exact missing fact and how the user can check it safely. No severity.
   - **Rejected:** disproved. Write one line on why, so it isn't re-reported next time.

## Step 4: List the bugs

Write the list in the reply, and add one summary entry to `progress.md`:

| ID | Severity | Verdict | Area | What's wrong | Steps to reproduce | Expected | Actual | Evidence (file:line) | Smallest fix |
|---|---|---|---|---|---|---|---|---|---|

Severity applies only to confirmed findings, and it can't be higher than the impact you actually showed:
- **Critical:** an anonymous attacker gets code execution, full database access, takeover of any account, or payment/money manipulation, or real data loss happens
- **High:** a security control is fully defeated with real consequences (auth bypass, reading or changing another user's or tenant's data, stored XSS against other users, an anonymous request can take the service down), or a main feature is broken
- **Medium:** a real problem with limited reach or unusual preconditions, a partly broken feature, weak validation, or slowness
- **Low:** minor info leak, cosmetic issue, or minor UX
- **Hardening note:** good practice that's missing but not exploitable (because another protection already stops it). Listed separately and never mixed into the bug list.

Also list **what was covered and passed**, **needs-validation items** with the check the user should do, and **what couldn't be tested** and why. Never claim the system is "fully secure". Say what was covered.

## Step 5: Tell the user, then fix

1. Show the user the list, most severe first, in simple words.
2. Fix on a branch `fix/devflow-test-<YYYY-MM-DD>` (or one branch per big bug), in order of severity. Fix at the point where the decision is made (the server-side check, not the UI). If a fix needs a product or design decision, or changes behaviour users rely on, ask first.
3. Add a regression test for each bug where possible, so it can't come back.
4. Re-test each fix the same way the bug was found, and confirm it's gone.
5. Add a `progress.md` entry per fix, and a **Lessons learned** line in `CLAUDE.md` for any bug pattern that could happen again.
6. If you're the main agent and the work is large, you may split fixes into tasks in `tasks.md` for child agents.
7. No merging into staging/main until the user says so.

## Step 6: Clean up

Remove load-test scripts, temporary tools, test accounts, test data and generated files that aren't needed. Run `git status` to confirm only the intended fixes remain. Tell the user what was removed.

## Deep security audit (optional)

For a full, formal security audit (security-critical apps, before a big launch, or when the user asks for a pen-test-style report), use Cloudflare's `security-audit` skill if it's installed. It runs a multi-agent audit with coverage tracking and verified JSON findings. Install it with:

```bash
npx skills add https://github.com/cloudflare/security-audit-skill --skill security-audit --global
```

Its reports go outside the project by default (`~/security-audit-skill/<repo>/run-N`). Bring its confirmed findings back into Step 4 and fix them with the devflow rules.
