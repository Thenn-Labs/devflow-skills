# Security Method

Used by `/devflow-test` Step 2C and Step 3. Adapted from Cloudflare's [security-audit-skill](https://github.com/cloudflare/security-audit-skill) (MIT License, © 2025-2026 Cloudflare, Inc.) and condensed for everyday app work. For a full formal audit, use that skill directly.

## The rule: boundary + result

Every security finding must name all five parts:

1. **Attacker:** who has less trust (anonymous visitor, normal user, other tenant, webhook sender, uploaded file, AI-model output)
2. **Input or action** they control
3. **Control** that should stop it (auth check, validation, rate limit, tenant filter, signature check)
4. **Boundary crossed:** what they reach that they shouldn't
5. **Result:** concrete damage to someone else or to the system (data read or changed, account taken, money, code execution, service down, operator's bill raised)

If any part is missing, it isn't a confirmed vulnerability. Common traps:
- A missing best practice that another protection already covers → **hardening note**
- Something that only affects the attacker's own account or data → not a vulnerability
- Behaviour that depends on hosting, CDN, proxy or provider settings that aren't in the repo → **needs validation**. Don't guess either way.
- A parser crash with no shared impact → not a vulnerability

## Safety while testing
- Prove things with the **smallest local check**: a unit test, a curl to localhost, a dummy account. Stop at the first proof.
- Don't probe deployed or shared systems, real users' data, or paid APIs without explicit permission.
- Don't build exploit chains, persistence, or anything beyond proving the defect.
- Use dummy users, data and secrets. Never print or copy real secrets or environment values into notes or reports.

## Core attack classes (check for every project)

**Injection.** Trace untrusted input to dangerous sinks: SQL/NoSQL queries, HTML output, shell commands, template engines, file paths, redirects, deserialization, regex, AI prompts. Also check:
- *second-order* injection: data stored safely, later used in a dangerous place by other code
- injection through field names, keys, headers and metadata, not just values
- injection into logs, caches, search indexes and analytics

**Access control.** Don't just check that a permission check exists. Check that it's the *right* check for the *right* resource:
- Is there another route to the same change that checks a weaker permission?
- Can a field in the request body override what should be restricted (`role`, `ownerId`, `price`, `tenantId`)?
- Endpoints that check login but not ownership (IDOR)
- The same resource reachable by several paths with different checks
- Bulk, batch, export and import operations checking every item

**Files and resources.** Path traversal (encoded sequences, symlinks, null bytes), SSRF (user-supplied URLs, webhooks, image fetchers, including after redirects), zip slip, unsafe deserialization, temp file handling, check-then-use races.

**Crypto and secrets.** Weak randomness for tokens or OTPs, hardcoded secrets, secrets in logs/URLs/errors/client responses, missing signature (HMAC) checks on webhooks, non-constant-time secret comparison, failing open when crypto errors.

**Business logic** (scanners can't find these, so check by hand):
- Skipping steps, going backwards, or replaying a finished flow (e.g. reusing a payment success callback)
- Partial failure: if step 2 of 3 fails, is step 1 undone?
- Races: double spend, double approve, coupon reuse, lost updates (check-then-act without a lock/transaction)
- Numbers: negative, zero, overflow, rounding, string vs number
- Time: expiry boundaries, timezones, clock skew
- Defaults: what happens when config is missing, a feature flag is off, or a dependency is down? Secure by default, or open?

**Feature abuse and data leaks.**
- Export/backup including other users', deleted or private data
- Import/restore bypassing validation or overwriting others' data
- Search, filters and sorting revealing hidden data
- Different errors, status codes, timing or response size for "doesn't exist" vs "no access" (user enumeration in login, reset or signup)
- Preview, draft or share links giving wider access than intended; private pages cached publicly
- Webhook or notification URLs usable for SSRF

**Chained problems.** Small allowed things that combine: one component trusting another's validation more than it should, data that is safe when stored but dangerous later, tokens or API keys gaining scope after refresh or role change, revoked access still working from cache, restore/undelete skipping current permission checks.

**Wildcard.** Look at the strange, half-finished, experimental, legacy or "temp/hack" code. Try API calls the UI never makes. Look for hidden endpoints, parameters and headers. Check git history for removed secrets or reverted security fixes. Compare what the tests cover with what they don't.

## "Obvious things" checklist (check every item, literally)

- [ ] Hardcoded passwords, API keys, tokens, private keys (grep `password`, `secret`, `apikey`, `token`, `Bearer`, `-----BEGIN`)
- [ ] `.env`, `credentials.json`, `*.pem`, `*.key` committed, now or in git history; `.gitignore` covers secrets, uploads and local config
- [ ] Security TODO/FIXME/HACK comments (`TODO: add auth`)
- [ ] Debug/dev mode switchable in production by env var, query parameter or header
- [ ] Test, seed or default credentials that work in production
- [ ] Unprotected `/admin`, `/debug`, `/test`, `/metrics`, `/env`, `/.env`, `/config`, `/health` with internal details
- [ ] Dependencies pinned with a lockfile; known CVEs (`npm audit` etc.)
- [ ] `eval`, `exec`, `child_process`, `Function()`, dynamic `import()` or `dangerouslySetInnerHTML` with user input
- [ ] CORS `*`, or a reflected origin with credentials allowed
- [ ] Cookies holding sessions missing `HttpOnly`, `Secure`, `SameSite`
- [ ] Open redirects (`redirect`, `return`, `next`, `url`, `goto`, `continue` parameters)
- [ ] HTTPS enforced (HSTS), no HTTP-only endpoints
- [ ] Production errors leaking stack traces, SQL, internal paths
- [ ] Security headers: CSP, frame-ancestors / X-Frame-Options, X-Content-Type-Options, Referrer-Policy
- [ ] Rate limiting and bot protection on auth, OTP, forms, and expensive or paid endpoints
- [ ] Passwords hashed with bcrypt/argon2/scrypt; reset tokens random, single-use and short-lived

A checklist item failing is a **lead**, not yet a finding. Trace its impact first. For example, a cookie without `HttpOnly` only matters if it holds something sensitive and JS doesn't need it.

## Domain sections (use the ones Step 1b found)

**Web, auth & sessions.** JWT: algorithm checks, `none` alg, signature verified, expiry checked, secret strength. OAuth/OIDC: `state` and PKCE, exact redirect URI match, account linking by unverified email. Sessions rotate on login, are invalidated on logout and password change. MFA/OTP: brute-force limits, can't be skipped by calling the next step directly. Password reset: token bound to the user, single use, not leaked via Referer. CSRF on state-changing requests with cookie auth.

**Client-side / browser.** DOM XSS (`innerHTML`, `dangerouslySetInnerHTML`, `v-html`, markdown renderers), `postMessage` without an origin check, clickjacking on sensitive actions, prototype pollution from merging user JSON, secrets or admin logic in the client bundle, tokens in `localStorage` exposed to XSS, WebSocket auth and origin checks.

**AI / LLM features.** Prompt injection from user content, documents, web pages or tool results that leads to actions the user didn't approve. Model output rendered as HTML or run as code/SQL/shell. Tools or agents acting with more permission than the requesting user. One user's data leaking into another's context, memory or RAG results. Unlimited prompt size or loops burning paid quota (needs per-user limits).

**Webhooks, queues & APIs.** Signature verification on every webhook (Stripe, Razorpay, GitHub…), checked against the raw body, with replay protection by timestamp/ID. Idempotent handlers (the same event twice doesn't double-credit). GraphQL depth, complexity and introspection limits. Messages from a queue not trusted blindly.

**Resource exhaustion & cost.** One request causing huge work: unbounded `limit`/page size, deep nested queries, regex backtracking, decompression bombs, image processing, fan-out to paid APIs. Body/upload size caps. Expensive work done before auth or rate limiting. Quotas keyed by something the attacker can change (IP header, new account). Work that keeps running after the client disconnects. Retry storms without backoff.

**Multi-tenant data & lifecycle.** Every query is filtered by tenant/owner at the database layer. Cache keys include the tenant/user. Search indexes and file storage paths are scoped. Deleted accounts and data are really gone (or access revoked) from backups, exports and caches. Signed file URLs expire and are scoped.

**Mobile, desktop & deep links.** Deep links or intents triggering sensitive actions without confirmation, WebView JS bridges exposed to remote content, exported Android components, secrets in the app bundle, certificate checks disabled, sensitive data in plain local storage or logs.

**Cloud & deployment config.** Public buckets, overly broad IAM roles, secrets in IaC, Docker images or CI logs, containers running as root, admin panels or databases exposed to the internet, preview/staging deployments open without protection and connected to production data.

**Supply chain & CI.** Lockfile present and used in CI (`npm ci`), no `curl | bash` in builds, GitHub Actions pinned and with least-privilege `permissions:`, `pull_request_target` not running untrusted code with secrets, no secrets printed in CI logs, typo-squatted or abandoned packages, postinstall scripts.

## Fix guidance
- Find the rule the code must enforce (for example "a user can only read their own invoices"), and enforce it at the **last trusted decision point** on the server, not in the UI.
- Prefer the smallest specific change plus a regression test over broad rewrites.
- Hardening notes go in a separate list. Suggest them, but don't present them as bugs.
