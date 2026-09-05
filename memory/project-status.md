---
name: project-status
description: 現在の進捗・直近の作業・次のステップ
type: project
updated: 2026-09-05
---

# moewbgt — Status

## 引き継ぎ（HANDOFF）

> 別のエージェント（Codex 等）や次のセッションが**この欄だけ読めば再開できる**状態を保つ。残すのは今使っている判断だけで、検討しただけの案は書かない。方針を決めた時・試行を捨てた時・検証を実行した時・セッションを終える時に更新する。

- **現在採用している方針（エージェント環境）**: jpops / kumagusu ではなく research-project-template 寄りの構成（`CLAUDE.md` + `AGENTS.md` + `.claude/settings.json` + `.codex/config.toml` + `memory/` + `TODO.md`）。skill の symlink は conf-macos の `deploy/manifest.tsv` で scope=both を宣言し、`.claude/skills/` と `.agents/skills/` の両方へ配備する。`.claude/settings.json` には renv 関連 hook（PreToolUse の `renv.lock` ゲート、Stop の drift チェック）を 2026-09-04 に戻してある。

- **現在採用している方針（パッケージ）**: WebAPI クライアント（`read_moe_forecast()` / `read_moe_survey()`）は 2026-09-03 に実装・マージ完了。対応表 `data/wbgt_pref_codes.rda` は 2026-09-04 に山口（`pref_cd = 81`）の `area_cd` を 10（九州）→ **8（中国）** へ修正した。**`area_cd` は仕様書から読み取れない** — 第1.1版 2-1節は地方名の行と都府県の並びを別々に置くだけで対応を書いておらず、並びは都道府県コードの単純な昇順で地方の切れ目を含まない。初版は並び順と気象庁の区分から推論していたが、どちらの手がかりも誤った方向を指していた。`getSurveyData` のレスポンスが `area_cd` と `pref_cd` を両方返すことを使い、`location_type=2` で全 60 件を照会して確定させた。気象庁は山口を「九州北部地方（山口県を含む）」に入れるが、環境省 WebAPI はこの 1 点で気象庁に従っていない。**修正は 7 ファイル**（`data-raw/wbgt_pref_codes.R` / `data/wbgt_pref_codes.rda` / `tests/testthat/test-data.R` / `R/data.R` / `man/wbgt_pref_codes.Rd` / `PROVENANCE.md` / `TODO.md`）。3 コミット `5951687` / `db14c90` / `a967dde` は push 済み。 **WebAPI の `date_to` は両端包含と実測で確定（2026-09-04、`356aebd`）したが、境界を 1 点重ねる設計（`R/moe_api.R` の `moe_api_intervals()` と二分の midpoint）は変えない** — 実測であって仕様書の保証ではないため。判明した意味は `@param date_to` と `README.md` に書いてある。

- **次に行う作業（1 つ）**: PR [#7](https://github.com/uribo/moewbgt/pull/7)（`feat/station-master`）をマージする。**CI は 8 ジョブすべて green**（2026-09-05 確認）。その先に残るのは #13（`mntr/dl/` の実測地点は 11 か 47 か）、#11（`final_wbgt_*` の無名列 `X4`）、#7 と #12（`SHA256SUMS` の同梱と凍結物の定期照合。運用の穴として同じ）、#8 の残り（`default_workflow_permissions` を `read` に戻すか、`renv` ジョブの timeout 実測、roxygen2 の版ずれ）、#9（`.vscode` のローカル NOTE）。

- **`TODO.md` #10 は 2026-09-05 に決着（乗り換えた）**: 直接配布の地点マスタ CSV を典拠に切り替えた。生バイト `inst/extdata/wbgt_point_master-20260515.csv` を **9 個目の凍結バイト**として追加（`SHA256SUMS` も 9 行、`shasum -c` 9/9 OK）し、`data-raw/wbgt_stations.R` から `data/wbgt_stations.rda`（865 行 × 18 列）を導出する。**既存の 8 ファイルは削除も改名もしない**（再取得不能な年度スナップショット＋公開リポジトリの破壊的変更）。導出時の変換は 4 つだけ: 日本語ヘッダーの並びを照合してから位置で英語名に読み替え、緯度経度を度＋分から 10 進度へ畳み、番人値 `9999-99-99` を `NA` にし、`wbgt_pref_codes` から `area_cd` / `pref_cd` を結合する。`station_no` は WebAPI の `wbgt_no` と同じ整数にしてあるので返り値に直接結合できる。触ったのは 12 ファイル（新規 4: `data-raw/wbgt_stations.R` / `data/wbgt_stations.rda` / `inst/extdata/wbgt_point_master-20260515.csv` / `man/wbgt_stations.Rd`、変更 8: `R/data.R` / `tests/testthat/test-data.R` / `SHA256SUMS` / `README.md` / `PROVENANCE.md` / `CLAUDE.md` / `AGENTS.md` / `TODO.md`）。

- **記録の誤りを 1 件訂正した（2026-09-05）**: 「配布版との差分 24 地点は新規」は誤り。実際は **865 = 稼働中 841 + 提供終了 24** で、24 のうち 22 件は 2011〜2023 年に提供終了した地点、新規稼働は 2 件だけ（71192 東祖谷 2025-09-04〜、88837 名瀬 2024-11-27〜）。旧 841 のうち 2 件（71191 京上・88836 名瀬）は提供終了になっている。`PROVENANCE.md`「上流の状況」と `TODO.md` #6 を訂正済み。**新しい事実**: 配布版は `実測開始日` が埋まる地点を 49 件（稼働中 47）持ち、大半が 2025-04-01 開始。`CLAUDE.md` は `mntr/dl/` を「11 地点」と書くが、これは配布物の主張であって未検証なので**数字は書き換えず** `TODO.md` #13 に残した。

- **2026-09-05 に確定した上流の事実（`TODO.md` #6・`PROVENANCE.md`「上流の状況」が正典）**: (1) 過去年度版のマニュアル PDF は **R07 / R08 のみ 200**、`R02_`〜`R06_` は **403**（存在しないパスは 404 を返すので、403 は「あるが配布していない」）。過去年度版マスタ CSV は日付名で 404。よって `inst/extdata/` の 8 ファイル（2022〜2024 年版は R04〜R06 の PDF から導出、2020 年版は生成経路が記録されていない）は**再取得不能な凍結バイトで確定**。(2) 直接配布の `wbgt_point_master-20260515.csv` は **865 行 × 18 列で `wbgt_stations*.csv`（841 × 4）の上位互換**。841 地点は全て含まれ観測所名も一致。**`地方` 列が山口を「中国」に置き、`wbgt_pref_codes` の `area_cd` 修正を上流が独立に裏づけた**。(3) **旧 CSV サービスのパス体系は 2026 年度も同一**（`read_moe_wbgt()` の 5 分岐と `read_moe_alert()` の 3 年分が end-to-end で通る。PROVENANCE 問題 5 解消 → 引き継いだ 7 件に未処理は無くなった）。(4) 旧 CSV の予測値も **摂氏 ×10 の整数**（`44132` が `240`）、実況値は摂氏の小数（`21.7`）で WebAPI と同じ規約。

- **導出元マニュアル PDF を二重化した（2026-09-05、ユーザー判断）**: 上流 403 の `R04`/`R05`/`R06_wbgt_data_service_manual.pdf` は `~/Documents/3_Resources/japan-heatstroke/data-raw/` に untracked で 1 コピーしか無かった（ユーザーの指摘で判明）。`~/Documents/4_Archives/_frozen/moewbgt/manuals/`（canonical）と OneDrive の同じ並び（offsite）へ複製し、6/6 一致・実体ありを確認。**リポジトリにバイトは入れない**。照合は新規の `data-raw/verify_frozen_manuals.sh`（`SHA256SUMS` とは別物。あちらは repo 内専用）。四半期ごと＋原稿の節目に走らせて `PROVENANCE.md` の照合ログに追記する運用が未設定（`TODO.md` #12）。2020 年版の元 PDF（`R02_…`）は上流にもローカルにも無い。

- **試して失敗したこと**: `TODO.md` #6 の旧 HANDOFF / `TODO.md` に書いてあった 1 つの URL（`getSurveyData?data_type=0&location_type=1&wbgt_nos=44132&date_from=20260901000000&date_to=20260901000000`）は `count` 0 を返し、境界判定に使えなかった。原因は 44132（東京）が実測地点（`wbgt_class` = 1）で推定値（`data_type` = 0）のレコードを持たないこと。再実行しない方法: 0 件応答の count だけで包含／排他を判定すること。レコードが返る範囲（別の `data_type` か location_type）で判定すること。

- **未確認の項目**: renv 導入時から持ち越しの 2 件。(a) **renv 1.2 はプロジェクトライブラリと sandbox をワークスペースの外**（`~/Library/Caches/org.R-project.R/R/renv/`）に置く。Codex は `workspace-write` で動くため、このリポジトリで Codex が `Rscript` を起動すると `.Rprofile` → `activate.R` がそのパスへ書こうとしうる。**落ちるのか警告だけなのか通るのかは未確認**。塞がっていた場合の候補は `RENV_PATHS_ROOT` をワークスペース内に向けるか、`.codex/config.toml` の `[sandbox_workspace_write]` で当該パスを許可するか。(b) 戻した PreToolUse の `renv.lock` ゲートは**まだ発火した実績が無い**。

- **renv 導入（PR [#3](https://github.com/uribo/moewbgt/pull/3)）は 2026-09-04 にマージ済み**（`e69b1f4`、8 ジョブ green）。設計判断（`R-CMD-check` と `renv` は別の契約を検証する／`RENV_CONFIG_AUTOLOADER_ENABLED: FALSE` が分離を担う／関門を `renv::status()$synchronized` に戻さない／GitHub 由来は SHA 固定）は **`CLAUDE.md` の CI 節が正典**。3 回連続で落ちた経緯と誤った診断は git 履歴（`cb606c6` / `4cb2cd1` / `cf95a58`）に残してあるので、この欄では繰り返さない。

- **最後に実行した検証と結果**（2026-09-05、#10 の乗り換え後）: `Rscript data-raw/wbgt_stations.R` が全ガードを通って `data/wbgt_stations.rda` を生成（865 行 × 18 列、31,608 バイト）。`shasum -a 256 -c SHA256SUMS` → **9/9 OK**。`R CMD INSTALL --library=<scratchpad>` → `roxygen2::roxygenise()`（`wbgt_stations.Rd` のみ新規。roxygen2 8.0.0 で 8.1.0 の警告が出るのは #8 の既知）→ `testthat::test_dir()` → **PASS 97 / FAIL 0 / WARN 0 / SKIP 0**（+19）。`air format . --check` → 差分なし。`R CMD build` + `R CMD check --no-manual` → **Status: OK**（0/0/0。`checking data for non-ASCII characters` も OK で、日本語を含む `.rda` を 2 つ持っていても marked UTF-8 の NOTE は出ない）。なお `renv::status()` は `diffobj 0.3.6 != 0.3.8` の 1 件で out-of-sync だが、これは今回の変更と無関係な手元ライブラリのドリフト（lockfile は触っていない）。

**How to apply:** セッション終了時に進捗が変化したらこのファイルを更新する。「引き継ぎ（HANDOFF）」欄は方針を決めた時・試行を捨てた時・検証を実行した時にも更新し、Codex 等へ引き継ぐときはこの欄を先に読ませる（グローバル指示「Codex への委任と引き継ぎ」）。
