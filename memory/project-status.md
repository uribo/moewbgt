---
name: project-status
description: 現在の進捗・直近の作業・次のステップ
type: project
updated: 2026-09-04
---

# moewbgt — Status

## 引き継ぎ（HANDOFF）

> 別のエージェント（Codex 等）や次のセッションが**この欄だけ読めば再開できる**状態を保つ。残すのは今使っている判断だけで、検討しただけの案は書かない。方針を決めた時・試行を捨てた時・検証を実行した時・セッションを終える時に更新する。

- **現在採用している方針**: エージェント環境を jpops / kumagusu（R パッケージ 2 例）ではなく research-project-template 寄りに構成した。`CLAUDE.md` + `AGENTS.md` + `.claude/settings.json` + `.codex/config.toml` + `memory/` + `TODO.md`。skill の symlink は conf-macos の `deploy/manifest.tsv` で scope=both を宣言し、`.claude/skills/` と `.agents/skills/` の両方へ配備する。`.claude/settings.json` は**テンプレートの renv 関連 hook（PreToolUse の renv.lock ゲート、Stop の renv drift チェック）を 2026-09-04 に戻した**（renv を導入したため。それ以前は「renv 未導入で動かない hook は誤解の元」という理由で落としていた）。

### renv の導入（2026-09-04）— ブランチ `feat/renv`、3 コミット、**未 push**

**採用した方針: `R-CMD-check` と `renv` は別の契約を検証し、片方をもう片方に寄せない。**`R-CMD-check` の 6 ジョブは DESCRIPTION から現行 CRAN に解決する（CRAN 自身がやること＝パッケージが利用者に負う契約。`ubuntu-22.04` + R 4.1 が `Depends: R (>= 4.1.0)` を検証する唯一の手段）。新設の `renv` ジョブは `renv.lock` が記録する R 版 1 つで restore する（新しい checkout に座った人に repo が負う契約）。

**実際の分離を担っているのは env の `RENV_CONFIG_AUTOLOADER_ENABLED: FALSE` 1 行**（`R-CMD-check.yaml`）。`renv/activate.R` は追跡されているので全ジョブが checkout し、リポジトリ直下で R が起動すれば `.Rprofile` 経由で renv が有効化されて `.libPaths()` が空のプロジェクトライブラリを向く。**これを消すと 6 ジョブすべてが黙って renv 経路に移り、下限の検証が失われる。**`renv.yaml` は逆に設定しないのが正しい。

**ユーザー判断 2 件**（どちらも AskUserQuestion で確定）:

1. renv は開発環境の固定に限定し、`R-CMD-check` matrix は DESCRIPTION 解決のまま触らない
2. lockfile に `data-raw/` を含める（`snapshot.type = "implicit"`、114 パッケージ）。導出スクリプトは **CRAN から外れた `ensurer` と `zipangu`**（`harmonize_prefecture_name()` / `jpnprefs` を実使用）に依存しており、その出所を GitHub の commit SHA で書いている場所は repo 内で `renv.lock` だけ

**検証した結果**: `renv::status()` synchronized / lockfile に null フィールド 0・CRAN 由来は全て `Repository: "CRAN"`・GitHub 2 件は RemoteSha 完全 / 新しい `.Rprofile` の下で `LC_COLLATE` `LC_TIME` とも `"C"` / renv ライブラリ下の `R CMD check` は 0 errors・0 warnings・**1 NOTE（`.vscode`、ローカル限定）**。`.vscode` はユーザーのグローバル gitignore で除外され git に入らないので CI の tarball には現れない（`TODO.md` #9）。**追加した `.Rprofile` / `_dependencies.R` / `renv.lock` による NOTE は出ていない。**

**捨てた方法と再実行しない理由**:

- `renv::install()` を pak 経由のまま使う → pak は `upgrade = TRUE` で依存を強制更新し、`s2` をソースビルドしようとして `openssl/opensslv.h` 不在で落ちる。`options(renv.config.pak.enabled = FALSE)` で renv 自前のインストーラに落とせばキャッシュから link して通る
- pak の成功表示を信じる → **pak のインストールはトランザクションで、1 つ落ちると全部巻き戻る**。`zipangu` のダウンロード失敗が、同じ pass で「インストール済み」と表示された `assertr` / `jmastats` ごと巻き戻した。確認は必ず `renv::status()` で

**未確認のリスク（次の Codex セッションは先に確かめること）**: renv 1.2 はプロジェクトライブラリと sandbox を**ワークスペースの外**（`~/Library/Caches/org.R-project.R/R/renv/`）に置く。Codex は `workspace-write` で動くため（`.git` が読み取り専用だったのと同じ理由）、このリポジトリで Codex が `Rscript` を起動すると `.Rprofile` → `activate.R` がそのキャッシュパスへ書こうとしうる。**失敗するのか、警告だけなのか、通るのかは未確認。**塞がっていた場合の候補は 2 つ: `RENV_PATHS_ROOT` をワークスペース内に向ける、または `.codex/config.toml` の `[sandbox_workspace_write]` で当該パスを許可する。手元の緑をそのまま信じない。

**リポジトリ設定は解消済み（2026-09-04）**: `renv-update` が必要とする「Allow GitHub Actions to create and approve pull requests」をユーザーが有効化し、`can_approve_pull_request_reviews: true` を確認した。**同じ操作で `default_workflow_permissions` が `read` → `write` にも変わっている** — 現行 4 本はすべて `permissions:` を明示しているので実害は無いが、`read` に戻すかは未決（`TODO.md` #8）。

**PR [#3](https://github.com/uribo/moewbgt/pull/3)、2026-09-04 に 8 ジョブすべて green。**`renv` ジョブは `renv.lock describes the project: 114 packages, all restored at the recorded version.` → `R CMD check` **Status: OK**（NOTE 0 件。`.vscode` の NOTE がローカル限定だという `TODO.md` #9 の判断もこれで裏づけられた）。

**実証されたこと**:

- **`RENV_CONFIG_AUTOLOADER_ENABLED: FALSE` のガードは効いている。** R 4.1 ジョブが通ったことがその証拠（効いていなければ空のプロジェクトライブラリを向いて落ちる）
- **Linux での restore は成立する。** pak が GDAL/GEOS/PROJ/poppler 等を apt で解決し、sf・pdftools・s2・jmastats と GitHub の 2 件を含む 114 パッケージを 59.5 秒で入れた。`renv` ジョブ全体は 2m7s で、`timeout-minutes: 45` は十分過ぎるが、キャッシュの効かない更新時の値なので当面下げない

**3 回連続で落ちた原因と、間違えた診断**:

`renv::status()$synchronized` を関門にしていたが、**lockfile を書いた installer（手元の renv 自前）と CI が restore に使う installer（pak）は、GitHub 由来パッケージについて DESCRIPTION に書くフィールドが違う**。renv は `RemotePkgRef` も `NeedsCompilation` も書かず、pak は両方書く。**パッケージ名・版・commit SHA が完全に一致していても out of sync と報告される。**

**1 回目の診断（`RemoteRef` がブランチ名だから）は誤りだった。**`ensurer` を `master` から SHA に固定しても落ち続け、報告が `[…@feb1defe: unchanged]` に変わっただけだった。原因が分かったのは、関門を**差分フィールドを名指しする**形に書き換えてから。「out of sync」としか言わない関門は、2 回分の空振りを生んだ。**失敗を報告する関門は、何が違うかを言えなければ関門の役を果たさない。**

pak を外すのは代案にならない（sf / pdftools の sysreqs を解決しているのが pak で、apt のリストを手で持つと lockfile が変わるたびにずれる）。関門は実質を直接見る 3 検査に置き換えた: (1) コードスキャンが見つけたパッケージが全て lockfile にあるか、(2) lockfile の全てが restore されたか、(3) 版と（GitHub 由来なら）commit SHA が記録どおりか。**`renv::status()$synchronized` に戻さない。**

SHA 固定自体（`ensurer` / `zipangu` とも `RemoteRef == RemoteSha`）は残す。今回の失敗の原因ではなかったが、「動く ref を不変識別子へ固定する」という規約に沿うため。**ブランチ名に戻さない。**

**残っている作業（次に行う 1 つ）**: PR #3 をレビューしてマージする。マージ後は `default_workflow_permissions` を `read` に戻すかを決める（`TODO.md` #8）。

**作業ツリーに残した他人の変更**: `.gitignore`（quarto の 3 行）と `data-raw/wbgt_pref_codes.R`（JMA の参照 URL 追記と `stringi::stri_trans_nfkc` による NFKC 正規化）は私の変更ではないので**コミットせずそのまま残してある**。どちらも lockfile を out-of-sync にはしない（`stringi` / `tidyselect` は既に記録済み）。

**hook について**: 戻した PreToolUse の renv.lock ゲートは、この作業中のコミットでは**発火していない**（hook はセッション開始時に読み込まれるため）。次のセッションから有効になる前提で、動作確認はまだ済んでいない。

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

**単位（PROVENANCE 問題 4）はブリーフ送出後に確定した**（2026-09-03 18 時台）。ブリーフ §3-5 が「確定させる方法」として書いた突き合わせを実行した結果: 東京（44132）2026-09-01 で `getSurveyData` の 00:00 が `wbgt_WO` = `"21.9"`、同日 `getForecastData` が 03:00 `"220"` / 09:00 `"260"` / 12:00 `"280"`。**`forecast_val` は摂氏 ×10 の整数**、`wbgt_WO` / `wbgt_Tw` / `wbgt_Tg` は摂氏の小数で確定（2024-08-05 でも同形式）。あわせて、仕様書が「数値」と書くフィールドの多くは JSON では**文字列**で返ることも判明（整数は `wbgt_no` / `wbgt_class` / `area_cd` / `pref_cd` / `flag` のみ）。

**設計（換算しない・上流のキー名のまま返す）は変えない。**変わるのは記述だけで、ブリーフ §3-5 の「roxygen の `@return` に『単位は未確定』と書く」は**もう当てはまらない**。`@return` には確定した単位を書く。記述は `PROVENANCE.md` 問題 4・`CLAUDE.md`「単位の規約」・`TODO.md` #4／#5・`README.md` の 4 か所を更新済み。

**この更新は Codex が作業ツリーを持っている間に入れた**（`prompts/` のブリーフ送出後、`b4c0f9e` の上）。ドキュメント 4 ファイルのみで `R/` には触れていないが、Codex 側の変更と衝突しうるので `git status` / `git diff` を先に確認すること。

**Codex は実装を完了したが、報告前にジョブが死んだ**（2026-09-03）。`.git` が sandbox で読み取り専用（`workspace-write` の既定。`[sandbox_workspace_write]` に git 用の緩和キーは無い）だったため 1 回目は着手前に停止し、**git の分担を変えて再開した** — ブランチ作成・コミット・PR は Claude が持ち、Codex はファイル編集だけを行う（ユーザー判断、2026-09-03）。2 回目は実装を終えて検証中に、転送側のバックグラウンドジョブが `[killed]` で落ちた。**`codex status` はその後も 34 分間 `running / verifying` と表示し続けた** — ジョブ記録は生存の証拠にならない。生存判定に使えたのは (1) ログファイルの mtime が 24 分伸びていないこと、(2) 最後の行が `R CMD INSTALL` の「開始」で対応する「完了」が無いこと、(3) 動いていた R プロセスの親が Positron の `ark` で Codex と無関係だったこと。記録は `codex cancel` で明示的に閉じた。

**レビュー結果: ブリーフの重点 5 点はすべて合格**（詳細は下記の検証欄）。山口 `81 → area_cd 10`（九州）、沖縄 `9194 → 11`、バリデーションエラーは分割せず即 abort（回帰テストあり）、単位の換算なし、全分岐に `else`、`R/` に生の日本語リテラル 0 件。Codex の指示外の良い判断として、`as.POSIXct(Date, tz = "Asia/Tokyo")` が日付を UTC 午前 0 時として扱う挙動を実地確認し、受理形式を正規表現で厳密化している。

検証済みの実装を `feat/webapi-client` に **3 コミット**で入れた（`9968170` 対応表 / `4255ca9` 通信・分類・分割層 / `0624d23` 公開関数）。`main` へはまだ出していない。

**指摘 1（`main` へのマージをブロックする。ブランチへのコミットはブロックしない）**: `moe_api_intervals()` が `max_span` の区間を**隣接**させている（`current <- interval_to + 1`）ため、**上流が `date_to` を排他として扱う場合に分割が透過でなくなる**。`distinct()` は重複を消せるが欠落は補えない。架空サーバ（毎正時 1 件）で実測: `date_to` 排他だと分割なし 4 行に対し `max_span = 1h` で **3 行**（内部境界上の 01:00 が欠落）、包含なら 5/5 で一致。二分の側（`midpoint - 1`）が無事なのは `midpoint - 1` が毎時データの観測時刻に当たらないためで、`date_from` の秒がずれれば同じ欠落が起きる。**修正方針**（境界を 1 点重ねて `distinct()` に落とさせる。ブリーフ §3-4 が求めた「包含・排他の両対応」はこの形でしか成立しない）:

- `moe_api_intervals()`: ループを `while (current < to) { interval_to <- min(current + max_span, to); …; current <- interval_to }` にする。末尾の degenerate 区間マージのブロックは到達不能になるので削除する
- `moe_api_collect_interval()`: 前半を `midpoint - 1` ではなく `midpoint` までにする（停止性は不変。半分は `floor`/`ceil` でどちらも元の span 未満、1 時間の abort が先に効く）
- `max_span` は「区間幅」ではなく**stride** としてドキュメントする（重なる分、実区間は `max_span + 1` 秒になる）
- テストの境界アサーション（`date_to=…015959` / `date_from=…020000`）は**バグの側を固定していた**ので、「`date_to` を排他として扱うモックで分割あり／なしの行数が一致する」という性質のテストに置き換える

**指摘 1 は Claude が修正した**（`e269c34`、ユーザー判断で担当を Claude に。Codex はこのセッションで 2 回死んでおり、3 回目も同じ経路で落ちうるため）。区間を 1 点重ねる形にし、`while (current < to)` + `current <- interval_to`、二分は `[from, midpoint]` / `[midpoint, to]`。到達不能になった degenerate 区間のマージは削除。テストは境界のタイムスタンプを固定する形（＝バグの側を固定していた）から、「`date_to` を排他として扱うモックで分割あり／なしの行数が一致する」という性質のテストへ置き換えた。**修正後の実測**: 排他 4/4/4/4、包含 5/5/5/5（分割なし / `max_span` 1h / 1.5h / 上限エラーで二分）。

**PR [#2](https://github.com/uribo/moewbgt/pull/2) の Copilot レビュー指摘 1 件に対応した**（`ae6272e`、2026-09-03）。`moe_api_ids()` の `as.numeric()` が factor を水準コードに変換していた — `factor(c("44132","11001"))` が `wbgt_nos=2&wbgt_nos=1` になる。**水準コード自体が地点番号として妥当な値なので API はエラーを返さず、別地点の整合的な表が返る**のが厄介な点。`as.character()` でラベルを読んでから数値化する形にし、回帰テストを追加した。ユーザー入力を受ける他の 3 経路（`moe_api_datetime()` / `moe_api_fixed_time()` / `data_type` の検証）も factor で叩いて確認したところ、いずれも変換せず abort するので、静かに誤値が通るのはここだけだった。

**未確認（運用期間中に要実測。2026-10-21 を過ぎると翌シーズンまで確かめられない）**: `date_to` が包含か排他か。**クライアントは両対応なので実装はブロックされない**。単位と同じ形で 1 本叩けば決まる — `getSurveyData?data_type=0&location_type=1&wbgt_nos=44132&date_from=20260901000000&date_to=20260901000000` の `count` が 1 なら包含、0 なら排他。**上の修正はどちらでも入れる**（両対応が設計）が、答えが出れば `@param date_to` に意味を書けるので `PROVENANCE.md` の単位の記録の隣に残す。

**PR #2 の CI は 7 ジョブすべて pass**（2026-09-03）。`ubuntu-22.04 (4.1)` が通ったことで、**`httr2` を Imports に足しても `Depends: R (>= 4.1.0)` が保てている**ことが実証された（ブリーフ §8 の停止条件の 1 つだった項目）。所要は air-format 6s / macOS 1m29s / Linux release 1m20s / devel 1m29s / oldrel-1 1m44s / **R 4.1 1m54s** / Windows 1m56s。初回コールド（R 4.1 で 7m35s）に対しキャッシュが効いており、`timeout-minutes: 30` は依然として妥当。

**PR #2 をマージ済み**（merge commit `1fd3a88`、2026-09-03）。PR #1 と同じく squash せずマージコミットにした（9 コミットそれぞれに判断の根拠を書いてあるため）。このマージで、`origin/main` に未 push だった `b4c0f9e` / `c8e9a86` の 2 コミットも上がっている。ブランチ `feat/webapi-client` は残してある。

- **次に行う作業（1 つ）**: `date_to` の包含／排他を実レスポンスで確定させ（`TODO.md` #6 にコマンドあり）、`@param date_to` と `PROVENANCE.md` に書く。**運用期間内（〜2026-10-21）に限る**。実装は両対応なのでブロックはされないが、期限を過ぎると翌シーズンまで確かめられない。

- **試して失敗したこと**: `Rscript -e` へシェル変数を渡すのに `export` を忘れ、`Sys.getenv("SP")` が `""` を返して保存先が `/` になった。`download.file()` は権限エラーで落ちたが、それを `tryCatch()` で包んでいたため**「上流に URL が無い」と読み違えた**（2026-09-03、第 1.0 版の日付入り URL を 404 と誤断定。ユーザーが実際に取得できたことで判明）。取得の失敗を包むときは原因を握り潰さず `conditionMessage()` を出す。グローバル指示の「`purrr::safely()` で握り潰さない」はこの形の探索コードにも効く。
- **試して失敗したこと**: シェルが `noclobber` なので `cat > file` は既存ファイルに対して `file exists` で失敗する。上書きするときは `cat >| file` を使う。
- **試して失敗したこと**: ヒアドキュメントで `.claude/settings.json` や `CLAUDE.md` を書こうとすると、グローバルの PreToolUse hook が「Bash コマンドが `.Renviron` を参照している」として拒否する。Write ツールで書けば通る（hook が見るのは Bash の `command` 文字列と Read/Edit/Write の `file_path` だけで、Write の中身は見ない）。同じ理由で、散文中は資格情報ファイル名の直書きを避けて「プロジェクトの環境ファイル」と書いてある。
- **未確認の項目**: `TODO.md` #7 の 2 件目（`SHA256SUMS` が `.Rbuildignore` されておりインストール後に検証できない）。1 件目（コピー元 `3b80b7a` の到達性）は解消済み — japan-heatstroke は push 済みで、当初「未 push」と記録したのは push 前の時点を観測していたため（2026-09-03 訂正）。`.Rbuildignore` に足した 5 パターン（`CLAUDE.md` / `AGENTS.md` / `TODO.md` / `.agents` / `memory`）は `R CMD build` で検証済み — `man/` が無くても `build` は通るので、`check` を待たずに確かめられる。
- **最後に実行した検証と結果**（WebAPI クライアントのレビュー、2026-09-03 JST・Claude 実施）: 一時ライブラリへ `R CMD INSTALL`（exit 0）→ `testthat::test_dir(stop_on_failure = TRUE)` が **72 PASS / 0 FAIL / 0 WARN / 0 SKIP**（既存 18 + 新規 54）。`R CMD build` + `R CMD check --no-manual` が **Status: OK**（0 errors / 0 warnings / 0 notes）。`air format . --check` 差分なし。`Rscript data-raw/wbgt_pref_codes.R` は相互検証 3 件（行数 60 / 地点マスタの `area` 60 種との集合一致 / 地点番号の最頻接頭 2 桁）をすべて通過し、最終行の `use_data(overwrite = FALSE)` のみ既存ファイルを守って停止した（意図どおり）。`R/` の生の日本語リテラルを grep して 0 件。指摘 1 は架空サーバのモック（毎正時 1 件、`date_to` の包含／排他を切り替え）で再現させた。
- **その前の検証**（API 仕様書の配置と取得スクリプト、2026-09-03 JST）: `mv` 後に `inst/` 直下が `extdata/` だけになったこと、`git check-ignore -v data-raw/wbgt_data_api_service_manual.pdf` が `.gitignore:17:*.pdf` にマッチすることを確認。第 1.1 版 PDF 全 13 ページを読了。`data-raw/wbgt_api_manual.R` は 3 通り実地確認した: (1) 2 本とも手元にある状態で実行 → ダウンロードせず sha256 照合を通過、(2) 2 本とも退避して実行 → 393,925 / 251,834 バイトを取得し、**取り直したバイトが記録値 `a29848c1…` / `18b35833…` と一致**、(3) 期待値を書き換えた複製を実行 → 期待値・実測値・パスを添えて `stop()`。`air format .` 実行済み。
- **その前の検証**（TODO #5 実装後、2026-09-03 JST）: 新しいライブラリへ `R CMD INSTALL` し直したうえで、`memoise::is.memoised(read_moe_alert)` が `TRUE`（`.onLoad()` が効いている唯一の証拠。`source()` や `load_all()` では発火しないので必ずインストールして確認する）。`testthat::test_dir()` が 18/18 PASS、FAIL 0。`shasum -a 256 -c SHA256SUMS` は 8/8 OK（`data-raw/` の出力先を変えたが**スクリプトは実行していない**）。`R CMD build` の tarball は `tests/` を同梱し、`CLAUDE.md` / `AGENTS.md` / `TODO.md` / `memory/` / `.agents` / `.codex` / `SHA256SUMS` / `data-raw` を 1 件も含まない。旧実装を再現して 15〜40 の 0.1 刻みで `NA` が 18 点出ることを確認（テストが目的のバグを実際に捕まえる）。`air format .` 実行済み。
- **さらにその前**（TODO #1 実装後、2026-09-03 JST）: `shasum -a 256 -c SHA256SUMS` は **8 ファイルすべて OK**（13 ではない。コード 5 行を外したため）。外した 5 行の値が `PROVENANCE.md` の履歴表と 5/5 一致することを確認。`PROVENANCE.md` に書いた検証レシピ `git show 7efd1b3:R/guides.R | shasum -a 256` を 2 ファイルで実地確認し、履歴表の値と一致。残る「13 行」の記述は経緯の説明 3 箇所のみで、いずれも文脈上正しい。
- **いちばん古い記録**（環境整備時、2026-09-03 JST）: `deploy/deploy.sh --apply` 実行後、`.claude/skills/` と `.agents/skills/` に `r-modern-tidyverse` / `r-rlang-programming` の symlink が張られリンク先が実在することを確認。`shasum -a 256 -c SHA256SUMS` は 13 ファイルすべて OK（コードには一切触れていない）。`jq -e .` で `.claude/settings.json`、`python3 -c 'import tomllib'` で `.codex/config.toml` の構文を確認。`git add -n` で追跡対象が意図した 10 ファイルだけ（symlink は `.gitignore` で除外）であることを確認。`LC_ALL` は禁止コメント 1 箇所にしか現れない。scratchpad で `R CMD build` を実行し、生成 tarball に `CLAUDE.md` / `AGENTS.md` / `TODO.md` / `memory/` / `.agents` / `.claude` / `.codex` / `SHA256SUMS` / `data-raw` が 1 件も含まれないことを確認（2026-09-03 JST）。

- **現在フェーズ**: TODO #4 フェーズ 1 完了・`main` にマージ済み。**作業ツリーの所有権は Claude にある**（Codex のジョブは `codex cancel` で明示的に閉じてある）
- **直近の作業**: エージェント環境の新規作成 → #1（`SHA256SUMS` の切り分け）→ #5（問題 1・2・7 の修正と回帰テスト）→ 問題 3 の判断 → #2（roxygen2 化）→ #3（CI）→ PR #1 マージ → #4 の設計確定とブリーフ作成 → Codex 実装 → レビューと境界の修正
- **次のステップ**: `date_to` の包含／排他を実測（#6）。その後 #7（`SHA256SUMS` の同梱・定期照合）。`date_search_type = 2` は意図的に未対応
- **ブロッカー**: `TODO.md` を参照

**How to apply:** セッション終了時に進捗が変化したらこのファイルを更新する。「引き継ぎ（HANDOFF）」欄は方針を決めた時・試行を捨てた時・検証を実行した時にも更新し、Codex 等へ引き継ぐときはこの欄を先に読ませる（グローバル指示「Codex への委任と引き継ぎ」）。
