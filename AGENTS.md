# Codex project instructions

Read and follow `CLAUDE.md` as the primary source of project knowledge and conventions. The rules below add Codex-specific constraints.

## Credential handling

- Never read, edit, print, search, summarize, or otherwise expose the project environment file, `.env`, credential JSON files, private keys, or files whose purpose is to store secrets.
- Do not bypass `.codex/config.toml` environment filtering or override `R_ENVIRON_USER` unless the user explicitly approves access for a specific task.
- If a task needs authenticated API access, explain which environment variable is required and obtain approval before enabling it. Never include credential values in prompts, logs, command output, or commits.

## Provenance

- `SHA256SUMS` covers the nine `inst/extdata/` files and nothing else. They are frozen bytes that may not be re-obtainable upstream, so a mismatch is always a defect. Never resolve one by rewriting the recorded digest, and never delete or overwrite those files. Report the mismatch instead.
- Do not add `R/` or `data-raw/` entries back to `SHA256SUMS`. Their copy-time digests are history, kept in `PROVENANCE.md`; putting them back makes the gate fire on intended edits. See the "SHA256SUMS の扱い" section of `CLAUDE.md`.
- Keep data retrieval fail-loud. Do not wrap it in `purrr::safely()` or `tryCatch()`.

## Handoff from Claude Code

- Before starting, read the "引き継ぎ（HANDOFF）" block at the top of `memory/project-status.md`, then check `git status` and `git diff`. Do not discard existing changes.
- Treat recorded decisions as claims: confirm them against the code and test results before building on them.
- When you finish or stop, update the HANDOFF block (current approach, the single next task, failed attempts, unverified items, last verification command and result).
