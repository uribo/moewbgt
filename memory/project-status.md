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

- **現在採用している方針（パッケージ）**: WebAPI クライアント（`read_moe_forecast()` / `read_moe_survey()`）は 2026-09-03 に実装・マージ完了。対応表 `data/wbgt_pref_codes.rda` は 2026-09-04 に山口（`pref_cd = 81`）の `area_cd` を 10（九州）→ **8（中国）** へ修正した。**`area_cd` は仕様書から読み取れない** — 第1.1版 2-1節は地方名の行と都府県の並びを別々に置くだけで対応を書いておらず、並びは都道府県コードの単純な昇順で地方の切れ目を含まない。初版は並び順と気象庁の区分から推論していたが、どちらの手がかりも誤った方向を指していた。`getSurveyData` のレスポンスが `area_cd` と `pref_cd` を両方返すことを使い、`location_type=2` で全 60 件を照会して確定させた。気象庁は山口を「九州北部地方（山口県を含む）」に入れるが、環境省 WebAPI はこの 1 点で気象庁に従っていない。**修正は 7 ファイル**（`data-raw/wbgt_pref_codes.R` / `data/wbgt_pref_codes.rda` / `tests/testthat/test-data.R` / `R/data.R` / `man/wbgt_pref_codes.Rd` / `PROVENANCE.md` / `TODO.md`）。3 コミット `5951687` / `db14c90` / `a967dde` は push 済み。 **WebAPI の `date_to` は両端包含と実測で確定（2026-09-04、`356aebd`）したが、境界を 1 点重ねる設計（`R/moe_api.R` の `moe_api_intervals()` と二分の midpoint）は変えない** — 実測であって仕様書の保証ではないため。判明した意味は `@param date_to` と `README.md` に書いてある。

- **次に行う作業（1 つ）**: PR [#4](https://github.com/uribo/moewbgt/pull/4)（ブランチ `docs/date-to-inclusive`、`main` は `origin/main` のまま）の CI 結果を見てマージする。その後は `TODO.md` #6 の残り（過去年度 CSV / マニュアル PDF の配布継続、`wbgt_point_master-20260515.csv` の列構成、旧 CSV パス体系）か #7（`SHA256SUMS` の同梱と定期照合）のどちらかに進む。

- **試して失敗したこと**: `TODO.md` #6 の旧 HANDOFF / `TODO.md` に書いてあった 1 つの URL（`getSurveyData?data_type=0&location_type=1&wbgt_nos=44132&date_from=20260901000000&date_to=20260901000000`）は `count` 0 を返し、境界判定に使えなかった。原因は 44132（東京）が実測地点（`wbgt_class` = 1）で推定値（`data_type` = 0）のレコードを持たないこと。再実行しない方法: 0 件応答の count だけで包含／排他を判定すること。レコードが返る範囲（別の `data_type` か location_type）で判定すること。

- **未確認の項目**: `read_moe_survey()` / `read_moe_forecast()` の `to <= from` ガード（`TODO.md` #6 記載。実装上の障害は無し: `moe_api_intervals()` は幅 0 で単一区間を返し、二分は `span <= moe_api_min_span` で停止する。API は `date_from == date_to` を受け付けるため、`to < from` に緩めるか `to == from` は許可するか検討必要）。さらに renv 導入時から持ち越している未確認が 2 件ある。(a) **renv 1.2 はプロジェクトライブラリと sandbox をワークスペースの外**（`~/Library/Caches/org.R-project.R/R/renv/`）に置く。Codex は `workspace-write` で動くため、このリポジトリで Codex が `Rscript` を起動すると `.Rprofile` → `activate.R` がそのパスへ書こうとしうる。**落ちるのか警告だけなのか通るのかは未確認**。塞がっていた場合の候補は `RENV_PATHS_ROOT` をワークスペース内に向けるか、`.codex/config.toml` の `[sandbox_workspace_write]` で当該パスを許可するか。(b) 戻した PreToolUse の `renv.lock` ゲートは**まだ発火した実績が無い**（hook はセッション開始時に読み込まれるため、戻した当のセッションでは効かなかった）。

- **renv 導入（PR [#3](https://github.com/uribo/moewbgt/pull/3)）は 2026-09-04 にマージ済み**（`e69b1f4`、8 ジョブ green）。設計判断（`R-CMD-check` と `renv` は別の契約を検証する／`RENV_CONFIG_AUTOLOADER_ENABLED: FALSE` が分離を担う／関門を `renv::status()$synchronized` に戻さない／GitHub 由来は SHA 固定）は **`CLAUDE.md` の CI 節が正典**。3 回連続で落ちた経緯と誤った診断は git 履歴（`cb606c6` / `4cb2cd1` / `cf95a58`）に残してあるので、この欄では繰り返さない。

- **最後に実行した検証と結果**: `R CMD INSTALL --library=<scratchpad> .` → exit 0、`roxygen2::roxygenise()` → `read_moe_forecast.Rd` / `read_moe_survey.Rd` の 2 件だけ更新、`testthat::test_dir()` → **PASS 78 / FAIL 0 / WARN 0 / SKIP 0**、`air format .` → 差分なし。環境省 WebAPI に生きた照会 12 本（Rscript + httr2 直叩き）を実行し、`date_from` / `date_to`（`getSurveyData`）と `range_date_from` / `range_date_to`（`getForecastData`）が**両端とも包含**であることを確定（始点＝終点の退化した範囲も受け入れられ 1 レコード返す）。毎正時から外した 00:30〜01:30 は 01:00 だけを返すため、境界は時刻そのものに対して判定される。根拠 URL と count は `PROVENANCE.md`「上流の状況」に記録。判明した意味を `@param date_to`（`read_moe_forecast.Rd` / `read_moe_survey.Rd`）と `README.md` に記載。PR #4 の CI は **8 ジョブすべて pass**（`R-CMD-check` 6 ジョブ 1m31s〜2m33s / `renv` 1m59s / `air-format` 6s、2026-09-04）。

**How to apply:** セッション終了時に進捗が変化したらこのファイルを更新する。「引き継ぎ（HANDOFF）」欄は方針を決めた時・試行を捨てた時・検証を実行した時にも更新し、Codex 等へ引き継ぐときはこの欄を先に読ませる（グローバル指示「Codex への委任と引き継ぎ」）。
