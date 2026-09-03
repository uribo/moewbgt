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

TODO #2（roxygen2 化）完了。`R CMD check` は **Status: OK**（0 errors / 0 warnings / 0 notes）、テスト 18/18。手書き `NAMESPACE` は削除し roxygen2 生成に置換、`man/*.Rd` 8 件を生成。`utils` を Imports に追加して `utils::download.file()` に修飾、未使用ローカル `domain_url` を削除、裸の `contains()` を `tidyselect::` で修飾、`"\u767a\u8868\u56de\u6570"` をエスケープ化、列名 9 個を `R/moewbgt-package.R` の `globalVariables()` に集約。

**消してはいけないもの**: `R/moe_alert.R` の `@importFrom rvest read_html`。`.onLoad()` の再束縛でインストール後の名前空間から `rvest::` が見えなくなるため、無いと dependencies の NOTE が復活する（再束縛を外して実証済み）。理由は当該行の直上コメントと `CLAUDE.md` にも書いてある。

TODO #5 のうち 3 件（PROVENANCE 問題 1・2・7）を 2026-09-03 に解消した。7 = `wbgt_guideline()` の帯を降順の `>=` 連鎖にして半開区間として連続させた（旧実装は 15〜40 の 0.1 刻みで 18 点が `NA`）。2 = memoise をトップレベルから `.onLoad()` へ（`R/moe_alert.R` 末尾に置き、collation 順に依存させていない）。1 = `data-raw/` の出力先を `inst/extdata/` へ（`file.exists()` ガードが凍結バイトを守るので外さない）。あわせて testthat 3e を導入し `tests/testthat/test-guides.R` を追加。残る 3・4・5・6 は `TODO.md` #5 に扱いを明記した。

PROVENANCE 問題 3（`wbgt_observe*.csv` の改名）は**改名しない**でユーザー判断が確定した（2026-09-03）。公開リポジトリの破壊的変更であり、API 移行でファイルごと不要になりうるため、改名のコストを払う前に前提が変わる。名前と中身の食い違いという事実は残るので、`README.md` / `PROVENANCE.md` / `CLAUDE.md` の記述を薄めないこと。これで TODO #5 に未処理は無い。

TODO #1 は選択肢 1 で決着済み（2026-09-03）。`SHA256SUMS` は `inst/extdata/` の 8 ファイル専用になり、コード 5 行のダイジェストは `PROVENANCE.md` の履歴表へ移した。決め手は 13 行が初期コミット `7efd1b3` の中身と 13/13 一致し、そのコミットが push 済みだったこと — 記録は既に git がオフサイト付きで持っており、ファイルが足していたのは「コミットでは素通りする改変を止める関門」だけで、それはコード側では意図した変更に発砲する向きだった。**`SHA256SUMS` にコード行を戻さない。**

- **次に行う作業（1 つ）**: `TODO.md` #3 — jpops の `.github/workflows/{R-CMD-check,air-format}.yaml` を移植する。#2 完了により**両方とも緑で始められる**。

- **試して失敗したこと**: ヒアドキュメントで `.claude/settings.json` や `CLAUDE.md` を書こうとすると、グローバルの PreToolUse hook が「Bash コマンドが `.Renviron` を参照している」として拒否する。Write ツールで書けば通る（hook が見るのは Bash の `command` 文字列と Read/Edit/Write の `file_path` だけで、Write の中身は見ない）。同じ理由で、散文中は資格情報ファイル名の直書きを避けて「プロジェクトの環境ファイル」と書いてある。
- **未確認の項目**: `TODO.md` #7 の 2 件目（`SHA256SUMS` が `.Rbuildignore` されておりインストール後に検証できない）。1 件目（コピー元 `3b80b7a` の到達性）は解消済み — japan-heatstroke は push 済みで、当初「未 push」と記録したのは push 前の時点を観測していたため（2026-09-03 訂正）。`.Rbuildignore` に足した 5 パターン（`CLAUDE.md` / `AGENTS.md` / `TODO.md` / `.agents` / `memory`）は `R CMD build` で検証済み — `man/` が無くても `build` は通るので、`check` を待たずに確かめられる。
- **最後に実行した検証と結果**（TODO #5 実装後、2026-09-03 JST）: 新しいライブラリへ `R CMD INSTALL` し直したうえで、`memoise::is.memoised(read_moe_alert)` が `TRUE`（`.onLoad()` が効いている唯一の証拠。`source()` や `load_all()` では発火しないので必ずインストールして確認する）。`testthat::test_dir()` が 18/18 PASS、FAIL 0。`shasum -a 256 -c SHA256SUMS` は 8/8 OK（`data-raw/` の出力先を変えたが**スクリプトは実行していない**）。`R CMD build` の tarball は `tests/` を同梱し、`CLAUDE.md` / `AGENTS.md` / `TODO.md` / `memory/` / `.agents` / `.codex` / `SHA256SUMS` / `data-raw` を 1 件も含まない。旧実装を再現して 15〜40 の 0.1 刻みで `NA` が 18 点出ることを確認（テストが目的のバグを実際に捕まえる）。`air format .` 実行済み。
- **その前に実行した検証と結果**（TODO #1 実装後、2026-09-03 JST）: `shasum -a 256 -c SHA256SUMS` は **8 ファイルすべて OK**（13 ではない。コード 5 行を外したため）。外した 5 行の値が `PROVENANCE.md` の履歴表と 5/5 一致することを確認。`PROVENANCE.md` に書いた検証レシピ `git show 7efd1b3:R/guides.R | shasum -a 256` を 2 ファイルで実地確認し、履歴表の値と一致。残る「13 行」の記述は経緯の説明 3 箇所のみで、いずれも文脈上正しい。
- **さらにその前**（環境整備時、2026-09-03 JST）: `deploy/deploy.sh --apply` 実行後、`.claude/skills/` と `.agents/skills/` に `r-modern-tidyverse` / `r-rlang-programming` の symlink が張られリンク先が実在することを確認。`shasum -a 256 -c SHA256SUMS` は 13 ファイルすべて OK（コードには一切触れていない）。`jq -e .` で `.claude/settings.json`、`python3 -c 'import tomllib'` で `.codex/config.toml` の構文を確認。`git add -n` で追跡対象が意図した 10 ファイルだけ（symlink は `.gitignore` で除外）であることを確認。`LC_ALL` は禁止コメント 1 箇所にしか現れない。scratchpad で `R CMD build` を実行し、生成 tarball に `CLAUDE.md` / `AGENTS.md` / `TODO.md` / `memory/` / `.agents` / `.claude` / `.codex` / `SHA256SUMS` / `data-raw` が 1 件も含まれないことを確認（2026-09-03 JST）。

- **現在フェーズ**: 引き継いだ既知の問題の解消。実装（WebAPI クライアント）は未着手
- **直近の作業**: エージェント環境の新規作成 → TODO #1（`SHA256SUMS` の切り分け）→ TODO #5（PROVENANCE 問題 1・2・7 の修正と回帰テスト）
- **次のステップ**: CI（#3）→ WebAPI クライアント設計（#4、フィクスチャによるネットワークテストを含む）
- **ブロッカー**: `TODO.md` を参照

**How to apply:** セッション終了時に進捗が変化したらこのファイルを更新する。「引き継ぎ（HANDOFF）」欄は方針を決めた時・試行を捨てた時・検証を実行した時にも更新し、Codex 等へ引き継ぐときはこの欄を先に読ませる（グローバル指示「Codex への委任と引き継ぎ」）。
