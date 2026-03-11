# Workspace Conventions

## Directory Structure

Claim state is stored within the calling project's workspace directory. The calling plugin or user specifies a `working_dir` parameter; cogni-claims creates a `cogni-claims/` subdirectory there.

```
{working_dir}/
└── cogni-claims/
    ├── claims.json              # Claim registry (all ClaimRecords)
    ├── sources/
    │   └── {url-hash}.json      # Cached source content per unique URL
    └── history/
        └── {claim-id}.json      # Full audit trail per claim
```

## File Specifications

### claims.json — Claim Registry

The primary index of all claims. Array of ClaimRecord objects.

```json
{
  "version": "1.0.0",
  "updated_at": "2026-02-23T14:30:00Z",
  "claims": [
    { ... ClaimRecord ... },
    { ... ClaimRecord ... }
  ]
}
```

Read/write pattern:
- Read entire file to get claim list
- Write entire file after modifications (atomic update)
- Always update `updated_at` on write

### sources/{url-hash}.json — Source Cache

Cached content from fetched source URLs. The filename is a deterministic hash of the URL.

```json
{
  "url": "https://example.com/ai-report",
  "fetched_at": "2026-02-23T14:32:00Z",
  "fetch_method": "webfetch",
  "status": "success",
  "content": "Full text content extracted from the source...",
  "content_length": 4523,
  "error": null
}
```

For failed fetches:
```json
{
  "url": "https://example.com/paywalled-report",
  "fetched_at": "2026-02-23T14:32:00Z",
  "fetch_method": "webfetch",
  "status": "failed",
  "content": null,
  "content_length": 0,
  "error": "403 Forbidden — source requires authentication"
}
```

Hash generation: Use the URL string to produce a short filesystem-safe hash. The claims-store.sh script provides this via `echo -n "$url" | shasum -a 256 | cut -c1-16`.

Cache rules:
- One file per unique URL
- Multiple claims sharing a URL reference the same cache file
- Re-verification re-fetches the source (updates cache)
- Cache is advisory — always re-fetch if user requests re-verification

### history/{claim-id}.json — Audit Trail

Complete lifecycle history for a single claim, recording every state transition.

```json
{
  "claim_id": "claim-abc123",
  "events": [
    {
      "event": "submitted",
      "timestamp": "2026-02-23T14:30:00Z",
      "data": { "statement": "...", "source_url": "...", "submitted_by": "cogni-tips" }
    },
    {
      "event": "verified",
      "timestamp": "2026-02-23T14:35:00Z",
      "data": { "status": "deviated", "deviations_count": 1 }
    },
    {
      "event": "resolved",
      "timestamp": "2026-02-23T15:00:00Z",
      "data": { "action": "corrected", "rationale": "..." }
    }
  ]
}
```

## Initialization

When cogni-claims is invoked for a project for the first time:

1. Check if `{working_dir}/cogni-claims/` exists
2. If not, create directory structure:
   ```
   mkdir -p {working_dir}/cogni-claims/sources
   mkdir -p {working_dir}/cogni-claims/history
   ```
3. Initialize `claims.json`:
   ```json
   {
     "version": "1.0.0",
     "updated_at": "<now>",
     "claims": []
   }
   ```

## Concurrency

The workspace is designed for single-session use. Multiple parallel claim-verifier agents may write to different source cache files simultaneously, but `claims.json` updates should be serialized through the orchestrator skill.

## Cross-Plugin Usage

Other plugins submit claims by invoking the cogni-claims:claims skill with:
- `mode`: "submit"
- `working_dir`: their project directory
- `claims`: array of {statement, source_url, source_title}
- `submitted_by`: their plugin name

The skill handles workspace initialization, ID assignment, and registry updates.
