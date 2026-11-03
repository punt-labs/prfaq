# Security Engineering

Application security, infrastructure hardening, and secure development
practices. Defense in depth: assume every layer will be breached and design
so that no single failure compromises the system.

## OWASP Top 10

The OWASP Top 10 is the baseline, not the ceiling. Every web-facing
application must address these categories.

### Injection

SQL injection, command injection, LDAP injection, template injection. The
pattern is always the same: untrusted data reaches an interpreter without
separation between code and data.

- Use parameterized queries. Never concatenate user input into SQL strings.
  `db.Query("SELECT * FROM users WHERE id = ?", id)` -- not
  `fmt.Sprintf("SELECT * FROM users WHERE id = %s", id)`.
- For shell commands, pass arguments as separate array elements.
  `exec.Command("convert", inputPath, outputPath)` -- never
  `exec.Command("sh", "-c", "convert " + inputPath)`.
- Template injection: if users supply template strings, sandbox the engine.
  Jinja2 sandboxed mode, Go `text/template` with restricted FuncMaps.
- ORM does not mean safe. Raw query methods in ORMs bypass parameterization.
  Audit every `.Raw()`, `.Exec()`, and `.QueryRow()` call.

### Broken Authentication

- Enforce strong password policies at registration, not just at login.
- Hash passwords with bcrypt, scrypt, or argon2id. Never MD5 or SHA-256 alone.
  Cost factor must make brute force impractical. For new systems, use bcrypt cost 13 or higher. Use cost 12 only when required for legacy compatibility.
- Rate-limit login attempts per account and per IP. Lock accounts after
  repeated failures with exponential backoff.
- Session tokens must be cryptographically random, at least 128 bits of
  entropy. Use `crypto/rand`, never `math/rand`.
- Invalidate sessions server-side on logout. Do not rely solely on cookie
  expiration.

### Cross-Site Scripting (XSS)

- Context-aware output encoding: HTML entity encoding for HTML body, JavaScript
  encoding for script contexts, URL encoding for href attributes.
- Use `html/template` in Go, which auto-escapes by context. Never use
  `text/template` for HTML output.
- Content-Security-Policy headers: `default-src 'self'` as the baseline.
  Avoid `unsafe-inline` and `unsafe-eval`.
- Sanitize rich text input with an allowlist-based sanitizer (e.g., bluemonday
  in Go). Denylists miss edge cases.

### Server-Side Request Forgery (SSRF)

- Validate and restrict URLs before fetching. Reject private IP ranges:
  `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`, `127.0.0.0/8`, `169.254.0.0/16`.
- Resolve DNS before connecting and re-check the resolved IP. DNS rebinding
  attacks change the resolution between check and connect.
- Use an allowlist of permitted hostnames or URL patterns when possible.
- Disable HTTP redirects or validate each redirect target.

### Other Categories

- **Security Misconfiguration**: default credentials, verbose error messages in
  production, unnecessary open ports, directory listing enabled. Automate
  configuration audits.
- **Vulnerable Components**: track dependencies, scan for CVEs, update promptly.
  See Dependency Security below.
- **Broken Access Control**: every endpoint checks authorization, not just
  authentication. Test for IDOR (Insecure Direct Object References) by
  accessing resources with another user's ID.
- **Cryptographic Failures**: data at rest and in transit must be encrypted.
  TLS 1.2+ only. No self-signed certs in production.
- **Insecure Design**: threat model before writing code, not after. Security
  cannot be bolted on to a fundamentally insecure design.

## Input Validation

All external input is hostile until proven otherwise. Validation happens at the
boundary, before data enters business logic.

### Allowlists Over Denylists

Denylists are incomplete by definition. They enumerate known-bad values and
miss everything else. Allowlists enumerate known-good values and reject
everything else.

- Define the valid character set, length range, and format for every input
  field. Reject anything outside that definition.
- For email: validate format with a well-tested library, then verify via
  confirmation email. Do not write your own email regex.
- For filenames: strip or reject path separators (`/`, `\`, `..`), null bytes,
  and control characters. Allowlist extensions if applicable.
- For numeric input: parse to the target type first, then check range.
  `strconv.Atoi` + bounds check, not regex.

### Boundary Validation

Validate at every trust boundary, not just the outermost one. The same data
may enter the system through multiple paths.

- HTTP handler validates request shape (content-type, required fields, size).
- Service layer validates business rules (user has permission, value is in
  valid range).
- Repository layer validates data constraints (foreign keys, unique constraints).
- Each layer validates what it owns. Do not rely on upstream validation.

### Encoding

- Decode input exactly once at the boundary. Validate after decoding.
  Double-decoding attacks exploit mismatched decode/validate ordering.
- Encode output for its target context (HTML, SQL, JSON, shell) at the
  point of use, not at the point of input.
- Be explicit about character encoding. Assume UTF-8 unless proven otherwise.
  Reject invalid byte sequences.

## Authentication and Authorization

### Least Privilege

- Every process, service account, and user gets the minimum permissions
  required for its function. No more.
- Database accounts for applications should not have DDL permissions. Read-only
  replicas for read-heavy services.
- API tokens should be scoped to specific operations. A deploy token should
  not read secrets. A read token should not write.
- Review permissions periodically. Accumulation of privileges over time is
  the norm; active pruning is the countermeasure.

### Session Management

- Session IDs: cryptographically random, regenerated after authentication
  state changes (login, privilege escalation). Prevents session fixation.
- Cookie attributes: `Secure` (HTTPS only), `HttpOnly` (no JavaScript
  access), `SameSite=Lax` or `Strict` (CSRF protection).
- Idle timeout (15-30 minutes for sensitive applications) and absolute
  timeout (8-12 hours). Both enforced server-side.
- Store session state server-side. Client-side session tokens (JWTs used
  as sessions) cannot be revoked without additional infrastructure.

### Token Handling

- JWTs: validate signature, issuer, audience, and expiration on every
  request. Reject tokens with `alg: none`. Pin the expected algorithm.
- Refresh tokens: store securely, rotate on use (one-time use), bind to
  client identity. Revoke all tokens for a user on password change.
- API keys: hash before storage (treat like passwords). Log key prefix
  for audit, never the full key.
- Short-lived tokens over long-lived ones. A 15-minute access token with
  a refresh flow is safer than a 30-day token.

## Secrets Management

### Never in Code

- No credentials, API keys, private keys, or connection strings in source
  code. Not in config files that are committed. Not in comments. Not in
  test fixtures (use fake values that cannot authenticate).
- Git history is permanent. A secret committed and then deleted is still
  in the history. Rotate the secret immediately; rewriting history is
  insufficient because the secret may already be cached.
- Pre-commit hooks to scan for secrets: `trufflehog`, `detect-secrets`,
  `gitleaks`. Run in CI as well.

### Environment Variables

- Acceptable for injecting secrets into applications at runtime. The
  application reads `os.Getenv("DATABASE_URL")` and never logs it.
- Environment variables are visible in `/proc/*/environ` on Linux and
  in process listings. For high-sensitivity secrets, prefer file-based
  injection or vault integration.
- `.env` files must be in `.gitignore`. Provide `.env.example` with
  placeholder values.

### Vault Patterns

- HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager, or similar.
  Application authenticates to vault at startup, retrieves secrets, holds
  them in memory only.
- Rotate secrets on a schedule. Vault-managed dynamic secrets (e.g.,
  short-lived database credentials) are preferred over static secrets.
- Encrypt secrets at rest and in transit. Audit access logs.

## Dependency Security

### CVE Scanning

- Run `govulncheck` for Go, `pip-audit` for Python, `npm audit` for Node
  in every CI pipeline. Block merges on critical/high findings.
- Subscribe to security advisories for major dependencies. GitHub
  Dependabot alerts are the baseline.
- Distinguish between runtime and dev-only dependencies. A CVE in a test
  framework is lower priority than one in a web framework.

### Lock Files

- Always commit lock files: `go.sum`, `uv.lock`, `package-lock.json`.
  Lock files pin exact versions and cryptographic hashes.
- `go.sum` contains hashes for all module versions. Do not edit manually.
  Use `go mod tidy` and verify the diff.
- Review lock file changes in PRs. A changed hash for an unchanged version
  is a supply chain attack indicator.

### Supply Chain Attacks

- Typosquatting: verify package names character by character when adding
  new dependencies.
- Dependency confusion: configure registries explicitly. Use scoped
  packages, private registries, or namespace reservations.
- Minimize dependencies. Every dependency is attack surface. If the
  functionality is 20 lines of code, write it instead of importing it.
- Pin to exact versions in production. Use `go.sum` verification. Enable
  `GONOSUMCHECK` only with explicit justification.

## Cryptography

### Do Not Roll Your Own

- Use standard library implementations: `crypto/aes`, `crypto/sha256`,
  `crypto/tls`, `golang.org/x/crypto/bcrypt`.
- Never implement encryption, hashing, or MAC algorithms from scratch.
  Subtle timing, padding, and state management errors create vulnerabilities
  invisible to tests.
- Avoid low-level primitives unless you are building a cryptographic library.
  Use high-level constructs: `crypto/tls` for transport, `age` or `gpg`
  for file encryption, `bcrypt`/`argon2id` for password hashing.

### Key Management

- Generate keys with `crypto/rand`. Never `math/rand`, never
  `time.Now().UnixNano()` as a seed.
- Store private keys encrypted at rest. Use OS keychains (macOS Keychain,
  Linux secret-service) or hardware security modules for high-value keys.
- Rotate keys on a schedule. Design systems so that key rotation does not
  require downtime -- support multiple active keys during transition.
- Separate signing keys from encryption keys. Different key for each
  purpose, each environment.

## API Security

### Rate Limiting

- Apply rate limits at the API gateway or reverse proxy. Per-user,
  per-IP, and global limits.
- Return `429 Too Many Requests` with a `Retry-After` header.
- Exponential backoff for automated clients. Do not let a single client
  monopolize capacity.
- Separate rate limits for authentication endpoints (stricter) and data
  endpoints.

### CORS

- `Access-Control-Allow-Origin` must never be `*` for authenticated APIs.
  Enumerate allowed origins explicitly.
- Validate the `Origin` header server-side. Do not reflect the request
  origin back without checking.
- Preflight caching: `Access-Control-Max-Age` reduces OPTIONS requests
  but ensure the allowed methods/headers are correct.

### Content-Type Validation

- Reject requests with unexpected `Content-Type`. An API expecting JSON
  should return `415 Unsupported Media Type` for form data.
- Parse request bodies with strict parsers. Do not accept both JSON and
  form-encoded on the same endpoint unless explicitly designed.
- Response `Content-Type` must match the body. `application/json` for
  JSON, not `text/html`. Incorrect content types enable sniffing attacks.

## File Upload Security

### Type Validation

- Check MIME type from the file header (magic bytes), not from the
  `Content-Type` header or file extension. Both are attacker-controlled.
- Allowlist permitted file types. If the feature needs images, accept
  `image/png`, `image/jpeg`, `image/gif` and nothing else.
- Re-encode images on the server. This strips embedded scripts and
  normalizes the format. Use a library like `image/png` in Go.

### Path Traversal

- Never use user-supplied filenames directly for storage. Generate a
  random filename (UUID or hash) and store the original name as metadata.
- If original filenames must be preserved, strip all path components:
  `filepath.Base(name)`, then reject names containing `..`, `/`, `\`,
  or null bytes.
- Store uploads outside the web root. Serve through a handler that sets
  correct headers (`Content-Disposition: attachment`).

### Size Limits

- Enforce maximum file size at the HTTP layer: `http.MaxBytesReader` in
  Go, `client_max_body_size` in nginx.
- Check size before reading the full body into memory. Streaming uploads
  with size checks prevent memory exhaustion.
- Set per-file and per-request limits. A multipart upload with 1000
  small files can exhaust resources even if each file is small.

## Logging and Monitoring

### Never Log Secrets

- Passwords, tokens, API keys, session IDs, credit card numbers, SSNs
  must never appear in logs. Not in plaintext, not in base64, not
  partially masked.
- Scrub request headers before logging: `Authorization`, `Cookie`,
  `X-API-Key`. Log that the header was present, not its value.
- Structured logging makes scrubbing easier. With key-value pairs, you
  can filter specific fields. With string concatenation, secrets hide
  in free-form text.
- Audit log output destinations. Logs shipped to third-party services
  carry the same sensitivity as the data they contain.

### Audit Trails

- Log authentication events: login, logout, failed login, password
  change, privilege escalation. Include timestamp, user ID, source IP.
- Log authorization failures: user X attempted to access resource Y
  without permission. This detects probing attacks.
- Log administrative actions: user creation, role changes, configuration
  changes. These are the actions an attacker performs after gaining access.
- Audit logs must be append-only. An attacker who compromises the
  application should not be able to delete their traces.

### Anomaly Detection

- Baseline normal behavior: request rate, error rate, login failure rate,
  geographic distribution of access.
- Alert on deviations: sudden spike in 401s, requests from unusual IPs,
  access patterns inconsistent with the user's history.
- Correlate events across services. A login from country A followed by
  an API call from country B within minutes is suspicious.
- Automate response for clear-cut cases: lock account after N failed
  logins, block IP after port scan detection.

## Security Review Methodology

### Threat Modeling

- Identify assets: what are you protecting? User data, API keys,
  session state, business logic integrity.
- Identify threats using STRIDE: Spoofing, Tampering, Repudiation,
  Information Disclosure, Denial of Service, Elevation of Privilege.
- Diagram data flows and trust boundaries. Every arrow crossing a
  trust boundary is a potential attack surface.
- Prioritize by impact and likelihood. A SQL injection in a public
  endpoint is higher priority than a CSRF on an admin-only page
  behind VPN.

### Attack Surface Analysis

- Enumerate all entry points: HTTP endpoints, WebSocket handlers,
  message queue consumers, cron jobs, CLI arguments, file watchers.
- For each entry point: what input does it accept? Who can reach it?
  What does it do with the input? What would happen if the input
  were malicious?
- Reduce attack surface: remove unused endpoints, disable debug modes
  in production, close unnecessary ports, drop unused dependencies.
- Assume breach: if an attacker compromises component X, what else
  can they reach? Network segmentation, least privilege, and
  encryption at rest limit blast radius.

### Code Review for Security

- Check every input boundary: HTTP handlers, file readers, environment
  variable parsers, database result mappers.
- Trace data from source to sink. If user input reaches a SQL query,
  a shell command, an HTML template, or a file path without
  sanitization, it is a vulnerability.
- Look for time-of-check-to-time-of-use (TOCTOU) bugs: checking a
  permission and then acting on it in separate steps allows races.
- Review error handling: do error messages reveal internal structure
  (stack traces, SQL errors, file paths)? They should not in production.
- Check for hardcoded secrets: grep for `password`, `secret`, `key`,
  `token` in string literals and config files.
