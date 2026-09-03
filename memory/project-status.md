---
name: project-status
description: 現在の進捗・直近の作業・次のステップ
type: project
updated: 2026-09-04
---

# moewbgt — Status

## 引き継ぎ（HANDOFF）

> 別のエージェント（Codex 等）や次のセッションが**この欄だけ読めば再開できる**状態を保つ。残すのは今使っている判断だけで、検討しただけの案は書かない。方針を決めた時・試行を捨てた時・検証を実行した時・セッションを終える時に更新する。

- **現在採用している方針（エージェント環境）**: jpops / kumagusu ではなく research-project-template 寄りの構成（`CLAUDE.md` + `AGENTS.md` + `.claude/settings.json` + `.codex/config.toml` + `memory/` + `TODO.md`）。skill の symlink は conf-macos の `deploy/manifest.tsv` で scope=both を宣言し、`.claude/skills/` と `.agents/skills/` の両方へ配備する。`.claude/settings.json` には renv 関連 hook（PreToolUse の `renv.lock` ゲート、Stop の drift チェック）を 2026-09-04 に戻してある。

- **現在採用している方針（パッケージ）**: WebAPI クライアント（`read_moe_forecast()` / `read_moe_survey()`）は 2026-09-03 に実装・マージ完了。対応表 `data/wbgt_pref_codes.rda` は 2026-09-04 に山口（`pref_cd = 81`）の `area_cd` を 10（九州）→ **8（中国）** へ修正した。**`area_cd` は仕様書から読み取れない** — 第1.1版 2-1節は地方名の行と都府県の並びを別々に置くだけで対応を書いておらず、並びは都道府県コードの単純な昇順で地方の切れ目を含まない。初版は並び順と気象庁の区分から推論していたが、どちらの手がかりも誤った方向を指していた。`getSurveyData` のレスポンスが `area_cd` と `pref_cd` を両方返すことを使い、`location_type=2` で全 60 件を照会して確定させた。気象庁は山口を「九州北部地方（山口県を含む）」に入れるが、環境省 WebAPI はこの 1 点で気象庁に従っていない。**修正は 7 ファイル**（`data-raw/wbgt_pref_codes.R` / `data/wbgt_pref_codes.rda` / `tests/testthat/test-data.R` / `R/data.R` / `man/wbgt_pref_codes.Rd` / `PROVENANCE.md` / `TODO.md`）。3 コミット `5951687` / `db14c90` / `a967dde` は push 済み。

- **次に行う作業（1 つ）**: `TODO.md` #6 の `date_to` が包含か排他かを実測する。`getSurveyData?data_type=0&location_type=1&wbgt_nos=44132&date_from=20260901000000&date_to=20260901000000` の `count` が 1 なら包含、0 なら排他。**季節運用のため 2026-10-21 を過ぎると今年度は試せない**。実装は境界を 1 点重ねて両対応なのでブロックはされないが、判明すれば `@param date_to` に意味を書ける。なお `curl` はこの環境の permission で拒否されるため、WebFetch 経由で叩くことになる。

- **試して失敗したこと**: `data-raw/wbgt_pref_codes.R` に `dplyr::across(tidyselect::where(is.character), stringi::stri_trans_nfkc)` を加えて NFKC 正規化を試みたが、この表に対する効果は 1 件だけ（`pref_cd == 17L` の半角カナ）で、それはファイル自身のコメント「その他の表記は一切正規化しない」と tests/testthat/test-data.R で明示的に固定している値だった。実行するとスクリプト自身の setequal ガードで停止する。ユーザーの意図は「表示用」だったため、方針は **join する側で正規化する**（典拠の転記列は上書きしない）と決定し、mutate は削除した。再実行しない方法: 導出スクリプトの tribble に一括正規化を掛けること。

- **未確認の項目**: `date_to` の包含／排他（`TODO.md` #6「上流の未確認事項」。運用期間内 〜2026-10-21 に実測必要）。実装は両対応なのでブロックはされない。`TODO.md` #8「renv」の `default_workflow_permissions` を `write` → `read` に戻すかも未決。さらに renv 導入時から持ち越している未確認が 2 件ある。(a) **renv 1.2 はプロジェクトライブラリと sandbox をワークスペースの外**（`~/Library/Caches/org.R-project.R/R/renv/`）に置く。Codex は `workspace-write` で動くため、このリポジトリで Codex が `Rscript` を起動すると `.Rprofile` → `activate.R` がそのパスへ書こうとしうる。**落ちるのか警告だけなのか通るのかは未確認**。塞がっていた場合の候補は `RENV_PATHS_ROOT` をワークスペース内に向けるか、`.codex/config.toml` の `[sandbox_workspace_write]` で当該パスを許可するか。(b) 戻した PreToolUse の `renv.lock` ゲートは**まだ発火した実績が無い**（hook はセッション開始時に読み込まれるため、戻した当のセッションでは効かなかった）。

- **renv 導入（PR [#3](https://github.com/uribo/moewbgt/pull/3)）は 2026-09-04 にマージ済み**（`e69b1f4`、8 ジョブ green）。設計判断（`R-CMD-check` と `renv` は別の契約を検証する／`RENV_CONFIG_AUTOLOADER_ENABLED: FALSE` が分離を担う／関門を `renv::status()$synchronized` に戻さない／GitHub 由来は SHA 固定）は **`CLAUDE.md` の CI 節が正典**。3 回連続で落ちた経緯と誤った診断は git 履歴（`cb606c6` / `4cb2cd1` / `cf95a58`）に残してあるので、この欄では繰り返さない。

- **最後に実行した検証と結果**: `R CMD INSTALL --library=<scratchpad> .` → exit 0、`testthat::test_dir()` → **PASS 78 / FAIL 0 / WARN 0 / SKIP 0**（テストは追加しておらず、既存の期待値 1 件を 10L → 8L に直しただけ）。`Rscript data-raw/wbgt_pref_codes.R` は相互検証 3 件（行数 60 / 地点マスタの `area` 60 種との集合一致 / 地点番号の最頻接頭 2 桁）をすべて通過し、最終行の `use_data(overwrite = FALSE)` のみ既存ファイルを守って停止（意図どおり）。API で確定した山口の `area_cd` 修正は `getSurveyData` の 2 時点リクエスト（2026-09-01 / 2024-08-05）で一致、地点番号 81011 / 81071 / 81116（須佐・萩・油谷）がローカル地点マスタと一致、修正後の表が中国 5 + 九州 7 に分かれることを確認。**push 後の CI は `a967dde` で 3 ワークフローとも success**（`R-CMD-check` 2m6s / `renv` 2m31s / `air-format` 12s）。

**How to apply:** セッション終了時に進捗が変化したらこのファイルを更新する。「引き継ぎ（HANDOFF）」欄は方針を決めた時・試行を捨てた時・検証を実行した時にも更新し、Codex 等へ引き継ぐときはこの欄を先に読ませる（グローバル指示「Codex への委任と引き継ぎ」）。
