@AGENTS.md

## Claude Code 固有の設定

> 規約の正典は [AGENTS.md](AGENTS.md) で、上の 1 行の import で全文が読み込まれる。**このファイルに書いた内容は Codex には届かない**ので、両方のエージェントに効かせたい規約は AGENTS.md 側に書く。

### hook（`.claude/settings.json`）

Claude Code 経由の操作にだけ効く層。ターミナルからのコミットには `.githooks/pre-commit` が対応する（clone ごとに `git config core.hooksPath .githooks` で有効化）。

- **PreToolUse**（Bash）: `renv.lock` を含むコミットでパッケージ差分を示して承認を求める
- **PreToolUse**（Bash）: `git commit` の前に `AGENTS.md` が Codex の 32 KiB 上限を超えていないか検査し、超えていればコミットを止める
- **PostToolUse**（Edit|Write）: R 系のファイルを `air format` で整形
- **PostToolUse**（Edit|Write）: `AGENTS.md` の編集後にサイズを検査
- **Stop**（全体）: `renv::status()` の drift を報告
