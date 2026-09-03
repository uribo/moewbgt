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

PR [#1](https://github.com/uribo/moewbgt/pull/1) をマージ済み（merge commit `84b2662`、2026-09-03）。squash せずマージコミットにしたのは、4 コミットそれぞれに判断の根拠を書いてあるため。`main` の CI も success。

**CI の実測（初回・キャッシュなし）**: air-format 9s / macOS release 1m32s / Windows release 2m18s / Linux release 2m44s / oldrel-1 2m55s / **R 4.1 7m35s** / devel 10m51s。`timeout-minutes: 30` はコールド最大の約 3 倍で妥当。ワークフローのコメントは「実測はまだ無い」のままなので、数回走ったら実測値に差し替える（小さな follow-up）。**宣言していた `Depends: R (>= 4.1.0)` の下限は、この PR の CI で初めて実証された。**

TODO #3（CI）完了。jpops の 2 ワークフローを移植し、PR で自己検証される状態にした。**R 4.1 のジョブは `Depends: R (>= 4.1.0)` を検証する唯一の手段**なので matrix から外さない。ローカルの `R CMD check` は macOS の R 4.6.1 一本しか通っておらず、宣言した下限は CI が初めて叩く。

TODO #2（roxygen2 化）完了。`R CMD check` は **Status: OK**（0 errors / 0 warnings / 0 notes）、テスト 18/18。手書き `NAMESPACE` は削除し roxygen2 生成に置換、`man/*.Rd` 8 件を生成。`utils` を Imports に追加して `utils::download.file()` に修飾、未使用ローカル `domain_url` を削除、裸の `contains()` を `tidyselect::` で修飾、`"\u767a\u8868\u56de\u6570"` をエスケープ化、列名 9 個を `R/moewbgt-package.R` の `globalVariables()` に集約。

**消してはいけないもの**: `R/moe_alert.R` の `@importFrom rvest read_html`。`.onLoad()` の再束縛でインストール後の名前空間から `rvest::` が見えなくなるため、無いと dependencies の NOTE が復活する（再束縛を外して実証済み）。理由は当該行の直上コメントと `CLAUDE.md` にも書いてある。

TODO #5 のうち 3 件（PROVENANCE 問題 1・2・7）を 2026-09-03 に解消した。7 = `wbgt_guideline()` の帯を降順の `>=` 連鎖にして半開区間として連続させた（旧実装は 15〜40 の 0.1 刻みで 18 点が `NA`）。2 = memoise をトップレベルから `.onLoad()` へ（`R/moe_alert.R` 末尾に置き、collation 順に依存させていない）。1 = `data-raw/` の出力先を `inst/extdata/` へ（`file.exists()` ガードが凍結バイトを守るので外さない）。あわせて testthat 3e を導入し `tests/testthat/test-guides.R` を追加。残る 3・4・5・6 は `TODO.md` #5 に扱いを明記した。

PROVENANCE 問題 3（`wbgt_observe*.csv` の改名）は**改名しない**でユーザー判断が確定した（2026-09-03）。公開リポジトリの破壊的変更であり、API 移行でファイルごと不要になりうるため、改名のコストを払う前に前提が変わる。名前と中身の食い違いという事実は残るので、`README.md` / `PROVENANCE.md` / `CLAUDE.md` の記述を薄めないこと。これで TODO #5 に未処理は無い。

API 仕様書 第 1.1 版（PDF・13 ページ）をローカルに保存した（2026-09-03）。置き場所は `data-raw/wbgt_data_api_service_manual.pdf` — 当初 `inst/` 直下に置かれていたが、`inst/` はインストール時にパッケージへ同梱されるため 385KB の上流 PDF が全ユーザーに配られてしまう。`data-raw/moe_wbgt_stations.R` が提供サービスマニュアル PDF を `data-raw/` へ上流のファイル名のまま落としているので、その規約に合わせた（`.Rbuildignore` 済み、`.gitignore` の `*.pdf` で追跡もされない）。決め手は仕様書 2-1 節が TODO #4 に要る JMA 系 `pref_cd` 表そのもので、抽出するなら既存の `file.exists()` ガードと同じ経路に乗ること。出所・sha256・版が動く URL であることは `PROVENANCE.md` の「上流の状況」に記録した。**`SHA256SUMS` には足していない** — 追跡されないファイルは関門にできないため。

取得処理を `usethis::use_data_raw("wbgt_api_manual")` で作った `data-raw/wbgt_api_manual.R` に置いた（2026-09-03）。`file.exists()` ガードで既存ファイルを上書きせず、取得後に `digest::digest(algo = "sha256")` で記録値と照合し、**一致しなければ `stop()` する**。`usethis::use_data()` の行は消した — まだデータセットを作らないため（2-1 節の `pref_cd` 表を抽出する段でこの下に `pdftools::pdf_text()` を足す）。

**上流の URL は 2 系統ある**（2026-09-03 確認）。版なしの `wbgt_data_api_service_manual.pdf` は現行版を指す動く URL、`_r080422.pdf` は第 1.0 版の掲載日入り URL で、**後者は取得できる**（251,834 バイト、`18b35833…`）。一方で第 1.1 版に対応する `_r080624.pdf` は存在しない。掲載日入りの複製は現行版ではなく**旧版に対して**作られている（差し替え時にアーカイブされる）ように見えるが、確認できるのは第 1.2 版が出た後。

スクリプトはこの 2 本を落とす形にした。`stable` 列で「掲載日入り＝中身が変わらない前提」と「動く URL」を区別し、`stop()` のメッセージを変えている（前者が止まったら異常、後者なら新しい版が出た可能性）。**PDF を git で追跡しない判断で確定**（2026-09-03、ユーザー）。`.gitignore` の `*.pdf` に例外は足さない — 仕様書は解析データではなく、取得スクリプトと sha256 の記録があれば再取得できるため。

**仕様書から読み取れた要点**: `getForecastData` の引数は `location_type`（1 地点別 / 2 都道府県別 / 3 全地点）× `date_search_type`（1 連続期間 / 2 特定期間 / 3 特定時刻）の組み合わせで、`wbgt_nos` / `pref_cds` / `fixed_time_dates` は同名パラメータの繰り返しで複数指定する（配列型）。日付時刻は 14 桁 `YYYYMMDDHHMMSS`。`getSurveyData` は `data_type`（0 実況推定値 / 1 実況実測値、複数指定可）と `date_from` / `date_to`。返り値は `status` / `data` / `count` / `errMsg` で、25,000 件超過時は `status: "error"` と定型の `errMsg` が返る（2-2 節）。**単位（PROVENANCE 問題 4）は仕様書に書かれていない** — `forecast_val` は例示が `"40"` `"-10"` `"0"` `"30"` `"80"` と 10 の倍数ばかりで ×10 に見えるが、仕様書には根拠が無く、実データで確かめるまで確定しない。`wbgt_WI`（データ品質情報 0〜4）の判定フローは 1-2-5 節にある。

TODO #1 は選択肢 1 で決着済み（2026-09-03）。`SHA256SUMS` は `inst/extdata/` の 8 ファイル専用になり、コード 5 行のダイジェストは `PROVENANCE.md` の履歴表へ移した。決め手は 13 行が初期コミット `7efd1b3` の中身と 13/13 一致し、そのコミットが push 済みだったこと — 記録は既に git がオフサイト付きで持っており、ファイルが足していたのは「コミットでは素通りする改変を止める関門」だけで、それはコード側では意図した変更に発砲する向きだった。**`SHA256SUMS` にコード行を戻さない。**

TODO #4（WebAPI クライアント）の設計を確定し、実装を Codex へ委任した（2026-09-03）。**ブリーフは `prompts/20260903-1700-webapi-client.md`**（`prompts/` は `.gitignore` に追加したので追跡されない。Codex は `prompts/` を自動では読まないので、このパスから読ませる）。決めた主な方針:

- HTTP 層は **httr2**（手元に 1.2.3）。**`httptest2` は使わない** — 未インストールでサンドボックスはネットワーク不可のため入れられない。代わりに `httr2::with_mocked_responses()` ＋ `tests/testthat/fixtures/` の手書き JSON でオフラインテストする
- 25,000 件上限は**行数の事前見積もりで割らず、上限エラーを受けてから期間を再帰的に二分する**（下限 1 時間、そこで超えたら `abort`）。境界の包含関係が仕様書に無いので、前半を `mid - 1 秒`で閉じたうえで自然キーで `distinct()` する
- **エラーは 2 種に分ける**: 件数上限（→ 分割）と、それ以外のバリデーションエラー（→ 即 `abort`）。一緒にすると無限二分する。API は HTTP 200 で `status: "error"` を返す想定なので body を見る必要がある（この想定自体は未検証）
- 単位（PROVENANCE 問題 4）は**換算しない**。上流のキー名（`forecast_val` / `wbgt_WO` / `wbgt_Tw` / `wbgt_Tg` / `wbgt_WI`）のまま numeric で返す。名前を `wbgt` に変えると摂氏だという主張になる
- 公開関数は `read_moe_forecast()` / `read_moe_survey()`。`location_type` / `date_search_type` は引数にせず、どの引数が与えられたかで決める（既存 `read_moe_wbgt()` の流儀）。ただし**分岐は必ず `else` で閉じる**
- 対応表は `data/wbgt_pref_codes.rda`（`LazyData: true` を追加）。`SHA256SUMS` には**足さない**（導出物）

**`pref_cd` 表について実測で確定した事実**（2026-09-03、`inst/extdata/wbgt_stations2024.csv` の集計）: 同ファイルの `area` は **60 種で仕様書 2-1 節の 60 エントリと 1 対 1**。同ファイルの `pref_code` 列は **JIS コード（01〜47）で API の `pref_cd` ではない**。`station_no` の上 2 桁が `pref_cd` と一致し（宗谷 11001 → 11、東京 44132 → 44）、**沖縄だけ接頭が 91/92/93/94 の 4 系列**ある（`pref_cd = 9194` はこの範囲の圧縮表記と読める）。北海道の一部は接頭が振興局境界とずれる（上川 12/15、空知 15、渡島 23/24、檜山 24）ので、接頭 2 桁は**検証手段であって典拠ではない**。典拠は PDF の表。地方コードと都道府県の対応は表のセルではなく**並び順**で示されているため転記事故が起きやすく、特に**山口（81）は中国地方ではなく九州のブロック**にある（JMA の慣行）。

- **次に行う作業（1 つ）**: Codex が上げてくる `feat/webapi-client` の PR を全文レビューする。重点は (a) `pref_cd` 60 行の転記、特に山口 81 の地方コードが 10（九州）になっているか、(b) バリデーションエラーで分割せず即停止するか（無限二分の回帰）、(c) 単位を勝手に ×0.1 していないか、(d) 分岐に `else` があるか、(e) `R/` に生の日本語リテラルが混ざっていないか。

- **試して失敗したこと**: `Rscript -e` へシェル変数を渡すのに `export` を忘れ、`Sys.getenv("SP")` が `""` を返して保存先が `/` になった。`download.file()` は権限エラーで落ちたが、それを `tryCatch()` で包んでいたため**「上流に URL が無い」と読み違えた**（2026-09-03、第 1.0 版の日付入り URL を 404 と誤断定。ユーザーが実際に取得できたことで判明）。取得の失敗を包むときは原因を握り潰さず `conditionMessage()` を出す。グローバル指示の「`purrr::safely()` で握り潰さない」はこの形の探索コードにも効く。
- **試して失敗したこと**: シェルが `noclobber` なので `cat > file` は既存ファイルに対して `file exists` で失敗する。上書きするときは `cat >| file` を使う。
- **試して失敗したこと**: ヒアドキュメントで `.claude/settings.json` や `CLAUDE.md` を書こうとすると、グローバルの PreToolUse hook が「Bash コマンドが `.Renviron` を参照している」として拒否する。Write ツールで書けば通る（hook が見るのは Bash の `command` 文字列と Read/Edit/Write の `file_path` だけで、Write の中身は見ない）。同じ理由で、散文中は資格情報ファイル名の直書きを避けて「プロジェクトの環境ファイル」と書いてある。
- **未確認の項目**: `TODO.md` #7 の 2 件目（`SHA256SUMS` が `.Rbuildignore` されておりインストール後に検証できない）。1 件目（コピー元 `3b80b7a` の到達性）は解消済み — japan-heatstroke は push 済みで、当初「未 push」と記録したのは push 前の時点を観測していたため（2026-09-03 訂正）。`.Rbuildignore` に足した 5 パターン（`CLAUDE.md` / `AGENTS.md` / `TODO.md` / `.agents` / `memory`）は `R CMD build` で検証済み — `man/` が無くても `build` は通るので、`check` を待たずに確かめられる。
- **最後に実行した検証と結果**（API 仕様書の配置と取得スクリプト、2026-09-03 JST）: `mv` 後に `inst/` 直下が `extdata/` だけになったこと、`git check-ignore -v data-raw/wbgt_data_api_service_manual.pdf` が `.gitignore:17:*.pdf` にマッチすることを確認。第 1.1 版 PDF 全 13 ページを読了。`data-raw/wbgt_api_manual.R` は 3 通り実地確認した: (1) 2 本とも手元にある状態で実行 → ダウンロードせず sha256 照合を通過、(2) 2 本とも退避して実行 → 393,925 / 251,834 バイトを取得し、**取り直したバイトが記録値 `a29848c1…` / `18b35833…` と一致**、(3) 期待値を書き換えた複製を実行 → 期待値・実測値・パスを添えて `stop()`。`air format .` 実行済み。
- **その前の検証**（TODO #5 実装後、2026-09-03 JST）: 新しいライブラリへ `R CMD INSTALL` し直したうえで、`memoise::is.memoised(read_moe_alert)` が `TRUE`（`.onLoad()` が効いている唯一の証拠。`source()` や `load_all()` では発火しないので必ずインストールして確認する）。`testthat::test_dir()` が 18/18 PASS、FAIL 0。`shasum -a 256 -c SHA256SUMS` は 8/8 OK（`data-raw/` の出力先を変えたが**スクリプトは実行していない**）。`R CMD build` の tarball は `tests/` を同梱し、`CLAUDE.md` / `AGENTS.md` / `TODO.md` / `memory/` / `.agents` / `.codex` / `SHA256SUMS` / `data-raw` を 1 件も含まない。旧実装を再現して 15〜40 の 0.1 刻みで `NA` が 18 点出ることを確認（テストが目的のバグを実際に捕まえる）。`air format .` 実行済み。
- **さらにその前**（TODO #1 実装後、2026-09-03 JST）: `shasum -a 256 -c SHA256SUMS` は **8 ファイルすべて OK**（13 ではない。コード 5 行を外したため）。外した 5 行の値が `PROVENANCE.md` の履歴表と 5/5 一致することを確認。`PROVENANCE.md` に書いた検証レシピ `git show 7efd1b3:R/guides.R | shasum -a 256` を 2 ファイルで実地確認し、履歴表の値と一致。残る「13 行」の記述は経緯の説明 3 箇所のみで、いずれも文脈上正しい。
- **いちばん古い記録**（環境整備時、2026-09-03 JST）: `deploy/deploy.sh --apply` 実行後、`.claude/skills/` と `.agents/skills/` に `r-modern-tidyverse` / `r-rlang-programming` の symlink が張られリンク先が実在することを確認。`shasum -a 256 -c SHA256SUMS` は 13 ファイルすべて OK（コードには一切触れていない）。`jq -e .` で `.claude/settings.json`、`python3 -c 'import tomllib'` で `.codex/config.toml` の構文を確認。`git add -n` で追跡対象が意図した 10 ファイルだけ（symlink は `.gitignore` で除外）であることを確認。`LC_ALL` は禁止コメント 1 箇所にしか現れない。scratchpad で `R CMD build` を実行し、生成 tarball に `CLAUDE.md` / `AGENTS.md` / `TODO.md` / `memory/` / `.agents` / `.claude` / `.codex` / `SHA256SUMS` / `data-raw` が 1 件も含まれないことを確認（2026-09-03 JST）。

- **現在フェーズ**: TODO #4（WebAPI クライアント）フェーズ 1 を Codex へ委任済み。**作業ツリーの所有権は Codex にある** — 戻るまで Claude 側はリポジトリへ書き込まない（ファイル編集・git の状態変更・`R CMD INSTALL` を含む。renv のサンドボックスロックと同様、同じプロジェクトで R を同時に走らせない）
- **直近の作業**: エージェント環境の新規作成 → #1（`SHA256SUMS` の切り分け）→ #5（問題 1・2・7 の修正と回帰テスト）→ 問題 3 の判断 → #2（roxygen2 化）→ #3（CI）→ PR #1 マージ → #4 の設計確定とブリーフ作成
- **次のステップ**: Codex の実装をレビュー（重点は上）。その後 TODO #6（上流の未確認事項）と #7（`SHA256SUMS` の同梱・定期照合）
- **ブロッカー**: `TODO.md` を参照

**How to apply:** セッション終了時に進捗が変化したらこのファイルを更新する。「引き継ぎ（HANDOFF）」欄は方針を決めた時・試行を捨てた時・検証を実行した時にも更新し、Codex 等へ引き継ぐときはこの欄を先に読ませる（グローバル指示「Codex への委任と引き継ぎ」）。
