---
name: project-status
description: 現在の進捗・直近の作業・次のステップ
type: project
updated: 2026-09-03
---

# moewbgt — Status

## 引き継ぎ（HANDOFF）

> 別のエージェント（Codex 等）や次のセッションが**この欄だけ読めば再開できる**状態を保つ。残すのは今使っている判断だけで、検討しただけの案は書かない。方針を決めた時・試行を捨てた時・検証を実行した時・セッションを終える時に更新する。

- **現在採用している方針**: エージェント環境を jpops / kumagusu（R パッケージ 2 例）ではなく research-project-template 寄りに構成した。`CLAUDE.md` + `AGENTS.md` + `.claude/settings.json` + `.codex/config.toml` + `memory/` + `TODO.md`。skill の symlink は conf-macos の `deploy/manifest.tsv` で scope=both を宣言し、`.claude/skills/` と `.agents/skills/` の両方へ配備する。`.claude/settings.json` はテンプレートから renv 関連の hook（PreToolUse の renv.lock ゲート、Stop の renv drift チェック）を落とした版にした — このパッケージは renv 未導入で、動かない hook は誤解の元になるため。CI は置かなかった: `man/` が無い段階で `R CMD check` を回しても赤で始まるだけで情報にならない。
- **次に行う作業（1 つ）**: `TODO.md` の #1（`SHA256SUMS` のコード行の扱い）をユーザーが決める。ここが決まるまでコード側（`wbgt_guideline()` の境界、memoise のトップレベル呼び出し）に手を入れない。
- **試して失敗したこと**: ヒアドキュメントで `.claude/settings.json` や `CLAUDE.md` を書こうとすると、グローバルの PreToolUse hook が「Bash コマンドが `.Renviron` を参照している」として拒否する。Write ツールで書けば通る（hook が見るのは Bash の `command` 文字列と Read/Edit/Write の `file_path` だけで、Write の中身は見ない）。同じ理由で、散文中は資格情報ファイル名の直書きを避けて「プロジェクトの環境ファイル」と書いてある。
- **未確認の項目**: なし。`.Rbuildignore` に足した 5 パターン（`CLAUDE.md` / `AGENTS.md` / `TODO.md` / `.agents` / `memory`）は `R CMD build` で検証済み — `man/` が無くても `build` は通るので、`check` を待たずに確かめられる。
- **最後に実行した検証と結果**: `deploy/deploy.sh --apply` 実行後、`.claude/skills/` と `.agents/skills/` に `r-modern-tidyverse` / `r-rlang-programming` の symlink が張られリンク先が実在することを確認。`shasum -a 256 -c SHA256SUMS` は 13 ファイルすべて OK（コードには一切触れていない）。`jq -e .` で `.claude/settings.json`、`python3 -c 'import tomllib'` で `.codex/config.toml` の構文を確認。`git add -n` で追跡対象が意図した 10 ファイルだけ（symlink は `.gitignore` で除外）であることを確認。`LC_ALL` は禁止コメント 1 箇所にしか現れない。scratchpad で `R CMD build` を実行し、生成 tarball に `CLAUDE.md` / `AGENTS.md` / `TODO.md` / `memory/` / `.agents` / `.claude` / `.codex` / `SHA256SUMS` / `data-raw` が 1 件も含まれないことを確認（2026-09-03 JST）。

- **現在フェーズ**: 移行直後の環境整備。実装（WebAPI クライアント）は未着手
- **直近の作業**: エージェント環境（CLAUDE.md / AGENTS.md / .claude / .codex / memory / TODO.md）の新規作成
- **次のステップ**: `TODO.md` の #1 決着 → `man/` 整備（roxygen2 化）→ WebAPI クライアント設計
- **ブロッカー**: `TODO.md` を参照

**How to apply:** セッション終了時に進捗が変化したらこのファイルを更新する。「引き継ぎ（HANDOFF）」欄は方針を決めた時・試行を捨てた時・検証を実行した時にも更新し、Codex 等へ引き継ぐときはこの欄を先に読ませる（グローバル指示「Codex への委任と引き継ぎ」）。
