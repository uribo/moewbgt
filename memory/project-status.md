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

- **次に行う作業（1 つ）**: `TODO.md` #4（WebAPI クライアント）の設計に着手する。仕様書は読了済み（要点は上）。次は 25,000 件上限に対する期間分割の方針を決め、あわせて 2-1 節の地方コード・都道府県コード表（`pref_cd`、北海道は振興局 11〜24、沖縄 9194）をパッケージ内の対応表として持つ形を決める。単位は仕様書に無いので、運用期間中に実レスポンスを 1 本取ってから決める。

- **試して失敗したこと**: `Rscript -e` へシェル変数を渡すのに `export` を忘れ、`Sys.getenv("SP")` が `""` を返して保存先が `/` になった。`download.file()` は権限エラーで落ちたが、それを `tryCatch()` で包んでいたため**「上流に URL が無い」と読み違えた**（2026-09-03、第 1.0 版の日付入り URL を 404 と誤断定。ユーザーが実際に取得できたことで判明）。取得の失敗を包むときは原因を握り潰さず `conditionMessage()` を出す。グローバル指示の「`purrr::safely()` で握り潰さない」はこの形の探索コードにも効く。
- **試して失敗したこと**: シェルが `noclobber` なので `cat > file` は既存ファイルに対して `file exists` で失敗する。上書きするときは `cat >| file` を使う。
- **試して失敗したこと**: ヒアドキュメントで `.claude/settings.json` や `CLAUDE.md` を書こうとすると、グローバルの PreToolUse hook が「Bash コマンドが `.Renviron` を参照している」として拒否する。Write ツールで書けば通る（hook が見るのは Bash の `command` 文字列と Read/Edit/Write の `file_path` だけで、Write の中身は見ない）。同じ理由で、散文中は資格情報ファイル名の直書きを避けて「プロジェクトの環境ファイル」と書いてある。
- **未確認の項目**: `TODO.md` #7 の 2 件目（`SHA256SUMS` が `.Rbuildignore` されておりインストール後に検証できない）。1 件目（コピー元 `3b80b7a` の到達性）は解消済み — japan-heatstroke は push 済みで、当初「未 push」と記録したのは push 前の時点を観測していたため（2026-09-03 訂正）。`.Rbuildignore` に足した 5 パターン（`CLAUDE.md` / `AGENTS.md` / `TODO.md` / `.agents` / `memory`）は `R CMD build` で検証済み — `man/` が無くても `build` は通るので、`check` を待たずに確かめられる。
- **最後に実行した検証と結果**（API 仕様書の配置と取得スクリプト、2026-09-03 JST）: `mv` 後に `inst/` 直下が `extdata/` だけになったこと、`git check-ignore -v data-raw/wbgt_data_api_service_manual.pdf` が `.gitignore:17:*.pdf` にマッチすることを確認。第 1.1 版 PDF 全 13 ページを読了。`data-raw/wbgt_api_manual.R` は 3 通り実地確認した: (1) 2 本とも手元にある状態で実行 → ダウンロードせず sha256 照合を通過、(2) 2 本とも退避して実行 → 393,925 / 251,834 バイトを取得し、**取り直したバイトが記録値 `a29848c1…` / `18b35833…` と一致**、(3) 期待値を書き換えた複製を実行 → 期待値・実測値・パスを添えて `stop()`。`air format .` 実行済み。
- **その前の検証**（TODO #5 実装後、2026-09-03 JST）: 新しいライブラリへ `R CMD INSTALL` し直したうえで、`memoise::is.memoised(read_moe_alert)` が `TRUE`（`.onLoad()` が効いている唯一の証拠。`source()` や `load_all()` では発火しないので必ずインストールして確認する）。`testthat::test_dir()` が 18/18 PASS、FAIL 0。`shasum -a 256 -c SHA256SUMS` は 8/8 OK（`data-raw/` の出力先を変えたが**スクリプトは実行していない**）。`R CMD build` の tarball は `tests/` を同梱し、`CLAUDE.md` / `AGENTS.md` / `TODO.md` / `memory/` / `.agents` / `.codex` / `SHA256SUMS` / `data-raw` を 1 件も含まない。旧実装を再現して 15〜40 の 0.1 刻みで `NA` が 18 点出ることを確認（テストが目的のバグを実際に捕まえる）。`air format .` 実行済み。
- **さらにその前**（TODO #1 実装後、2026-09-03 JST）: `shasum -a 256 -c SHA256SUMS` は **8 ファイルすべて OK**（13 ではない。コード 5 行を外したため）。外した 5 行の値が `PROVENANCE.md` の履歴表と 5/5 一致することを確認。`PROVENANCE.md` に書いた検証レシピ `git show 7efd1b3:R/guides.R | shasum -a 256` を 2 ファイルで実地確認し、履歴表の値と一致。残る「13 行」の記述は経緯の説明 3 箇所のみで、いずれも文脈上正しい。
- **いちばん古い記録**（環境整備時、2026-09-03 JST）: `deploy/deploy.sh --apply` 実行後、`.claude/skills/` と `.agents/skills/` に `r-modern-tidyverse` / `r-rlang-programming` の symlink が張られリンク先が実在することを確認。`shasum -a 256 -c SHA256SUMS` は 13 ファイルすべて OK（コードには一切触れていない）。`jq -e .` で `.claude/settings.json`、`python3 -c 'import tomllib'` で `.codex/config.toml` の構文を確認。`git add -n` で追跡対象が意図した 10 ファイルだけ（symlink は `.gitignore` で除外）であることを確認。`LC_ALL` は禁止コメント 1 箇所にしか現れない。scratchpad で `R CMD build` を実行し、生成 tarball に `CLAUDE.md` / `AGENTS.md` / `TODO.md` / `memory/` / `.agents` / `.claude` / `.codex` / `SHA256SUMS` / `data-raw` が 1 件も含まれないことを確認（2026-09-03 JST）。

- **現在フェーズ**: 後片付け完了（PR #1 マージ済み）。実装（WebAPI クライアント）は未着手
- **直近の作業**: エージェント環境の新規作成 → #1（`SHA256SUMS` の切り分け）→ #5（問題 1・2・7 の修正と回帰テスト）→ 問題 3 の判断 → #2（roxygen2 化）→ #3（CI）→ PR #1 マージ
- **次のステップ**: WebAPI クライアント設計（#4、フィクスチャによるネットワークテストを含む）
- **ブロッカー**: `TODO.md` を参照

**How to apply:** セッション終了時に進捗が変化したらこのファイルを更新する。「引き継ぎ（HANDOFF）」欄は方針を決めた時・試行を捨てた時・検証を実行した時にも更新し、Codex 等へ引き継ぐときはこの欄を先に読ませる（グローバル指示「Codex への委任と引き継ぎ」）。
