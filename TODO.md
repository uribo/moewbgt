# TODO

GitHub Issue はまだ使っていないので、未決着の判断と次に行う作業をここに置く。各項目には**いま対応するか、次に回すか**を必ず書く。

## 1. `SHA256SUMS` のコード行をどう扱うか

**扱い: 完了（2026-09-03）** — 選択肢 1 を採用。コード 5 行を `SHA256SUMS` から外し、コピー時点のダイジェストを `PROVENANCE.md` の履歴表へ移した。`SHA256SUMS` は `inst/extdata/` の 8 ファイル専用になり、**失敗＝常に異常**に戻った。これで #5（コード側の修正）のブロックが外れている。

決め手は、`SHA256SUMS` の 13 行が**このリポジトリの初期コミット `7efd1b3` の中身と 13/13 一致し、そのコミットが push 済み**だったこと。記録の内容は既に git がオフサイト付きで保持しているので、ファイルが足しているのは「コミットでは素通りする改変を止める関門」だけになる。その関門は変わってはいけない `inst/extdata/` に対しては有効だが、コード側では**意図した変更に対して発砲する**ため向きが逆だった。

補強材料: `SHA256SUMS` は `.Rbuildignore` されているため、仮に kumagusu の `inst/provenance/` 方式で同梱してもコード行は検証できない（インストール後に `R/*.R` は lazyload DB になり、`data-raw/` は build 対象外）。コード行はソースツリー以外のどの文脈でも検証不能だった。

**戻さないこと**: `SHA256SUMS` にコード行を再追加しない（`CLAUDE.md` / `AGENTS.md` にも明記）。

## 2. roxygen2 化と `man/` 生成

**扱い: 完了（2026-09-03）** — `R CMD check` が **Status: OK**（0 errors / 0 warnings / 0 notes）になった。

- 7 つの export すべてに roxygen コメントを書き、`man/*.Rd` 8 件を生成。`NAMESPACE` は手書きを削除して roxygen2 生成に置き換えた
- `utils` を `Imports` に足し、`download.file()` を `utils::` で修飾。`read_moe_wbgt()` 内の未使用ローカル `domain_url` を削除
- 裸の `contains("/")` を `tidyselect::contains("/")` に修飾
- データマスキングの列名 9 個を `R/moewbgt-package.R` の `utils::globalVariables()` に集約
- 非 ASCII 警告の原因だった `"発表回数"` を Unicode エスケープに変換
- `@importFrom rvest read_html` を追加。**冗長に見えるが必要**: `.onLoad()` の再束縛によりインストール後の名前空間から `rvest::` が見えず、無いと「All declared Imports should be used」の NOTE が出る（再束縛を外して確認済み）

残るテスト整備は #3 ではなくこの先の課題として: ネットワークを叩く `read_moe_alert()` / `read_moe_wbgt()` は季節運用のためフィクスチャ（`httptest2` / `vcr`）が要り、#4 の論点と共通なのでそちらで扱う。

## 3. CI

**扱い: 完了（2026-09-03）** — jpops の 2 ワークフローを移植した。#2 完了により**両方とも緑で始まる**（当初「`R-CMD-check` は `man/` 整備までは赤」としていた前提は解消済み）。

- `.github/workflows/R-CMD-check.yaml` — 6 ジョブ（macOS / Windows / Linux の release、Linux の devel・oldrel-1、`ubuntu-22.04` + R 4.1）。**R 4.1 のジョブは `DESCRIPTION` の `Depends: R (>= 4.1.0)` を検証する唯一の手段**なので外さない。vignette が無いので `build_args` は `--no-manual` のみ
- `.github/workflows/air-format.yaml` — `air format . --check`。`R tests` ではなく全体を見るのは、`air.toml` に exclude が無く `data-raw/` も整形対象だから。狭めると `data-raw/` のドリフトを CI が見逃す
- どちらも `timeout-minutes` を入れてある（既定の 6 時間は、ハングしたときに 360 runner-minutes を捨てる）。**このリポジトリでの実測はまだ無い**ので、数回走らせてから見直す。超えたら外すのではなく数字を上げる

## 4. WebAPI クライアント（本命）

論点は `README.md` と `PROVENANCE.md` にある。設計時に決めること:

- 1 リクエスト 25,000 件上限に対する期間分割・再結合・リトライ
- JMA 系 `pref_cd` の対応表（JIS コードではない。北海道は振興局で 11〜24、沖縄は `9194`）
- 季節運用のため、生きた API を叩くテストは運用期間外に落ちる。`httptest2` / `vcr` のフィクスチャ前提
- **単位は決着済み**（PROVENANCE 問題 4、2026-09-03）。`wbgt_WO` / `wbgt_Tw` / `wbgt_Tg` は摂氏の小数、`forecast_val` は摂氏 ×10 の整数。**換算せず上流のキー名のまま返す**方針は変えず、単位は roxygen に「未確定」ではなく確定した内容として書く。仕様書が「数値」と書くフィールドの多くは JSON では文字列で返るので、型を仕様書の記載から決めない
- `wbgt_WI`（データ品質情報 0〜4）は欠測補完の有無を示すので落とさない

**扱い: フェーズ 1 完了（2026-09-03）** — `feat/webapi-client` で実装した。設計は Claude、実装は Codex、レビューと git は Claude という分担（`.git` が Codex の sandbox で読み取り専用のため）。

- `read_moe_forecast()` / `read_moe_survey()` を追加。`location_type` / `date_search_type` は引数にせず、与えられた引数から決める。全分岐を `else` で閉じてある
- 25,000 件上限は**上限エラーを受けてからの再帰的二分**で扱う（行数の事前見積もりはしない）。バリデーションエラーとは `moe_api_classify()` で明示的に分離する。**混ぜると無限に二分する**
- **リクエストの境界は隣接させず 1 点重ねる。** 上流が `date_to` を包含として扱うか排他として扱うかは仕様書に書かれておらず、重ねる形だけが両方の読みで正しい。隣接させると排他の場合に境界上の行が黙って落ち、**分割の有無で結果が変わる**（実測で 4 行 → 3 行）。`distinct()` は重複を消せるが欠落は補えない
- `max_span` は区間幅ではなく **stride**
- 対応表は `data/wbgt_pref_codes.rda`（60 行）。生成時に 3 通りの相互検証を行う
- テストはネットワーク不要（`httr2::with_mocked_responses()` + 手書き JSON フィクスチャ）。**`httptest2` は使っていない** — 未インストールでサンドボックスから入れられず、結果として不要だった（純粋関数の単体テストで足りる）

**残り**: `date_search_type = 2`（`fixed_time_dates`）は未対応。二分の handle が無く、同じ範囲は `date_search_type = 1` で表現できるため意図的に外した。必要になったら別項目として立てる

## 5. 引き継いだ既知の問題 7 件

`PROVENANCE.md` の「引き継いだ既知の問題」を参照。**7 件のうち 3 件（1・2・7）を 2026-09-03 に解消した。**

- **7**（`wbgt_guideline()` が `27.5` や `30.5` で `NA`）— 降順の `>=` 連鎖に置換。回帰テスト `tests/testthat/test-guides.R` を追加（testthat 3e、18 assertion）。あわせて 4 語を Unicode エスケープに変換
- **2**（memoise がトップレベル）— 素の関数 + `.onLoad()` に変更。`R/moe_alert.R` の末尾に置き、collation 順に依存させていない
- **1**（`data-raw/` の出力先）— `inst/extdata/` に変更（12 箇所）。`file.exists()` ガードにより既存の凍結バイトは上書きされない

**残り 4 件の扱い**（うち 4 はその後 2026-09-03 に解消した）:

- **3**（`wbgt_observe*.csv` の改名）— **判断済み: 改名しない（現状維持、2026-09-03、ユーザー判断）**。公開リポジトリの破壊的変更にあたること、japan-heatstroke 側でも同じ理由で保留されていること（同 repo `TODO.md` 項目 1）、そして API 移行でファイルごと不要になる可能性が高いことから、改名のコストを払う前に前提が変わりうる。**名前と中身の食い違いという事実自体は残る**ので、`README.md`・`PROVENANCE.md`・`CLAUDE.md` の 3 か所で明示する現状の記述を薄めない。再検討するとすれば #4（WebAPI クライアント）で、このファイルが不要と確定したときに削除の可否として扱う
- **4**（単位の規約）— **解消（2026-09-03）**。生きた API に照会し、`getSurveyData` は摂氏の小数、`getForecastData` の `forecast_val` は摂氏 ×10 の整数であることを確定した。裏づけと再現手順は `PROVENANCE.md` の問題 4、換算の規約は `CLAUDE.md`「単位の規約」
- **5**（パス体系が 2026 年度も同一か）— 外部アクセスを伴う。#6 と併せて確認する
- **6**（`man/` が無い）— #2 と同一の項目。**そちらで解消済み（2026-09-03）**

**扱い**: 1・2・4・7 は完了、3 は判断済み（改名しない）。残る 5・6 は他項目に統合済みなので、この項目に未処理は無い

## 6. 上流の未確認事項

- 過去年度版のマスタ CSV とマニュアル PDF が今も配布されているか（配布されていなければ `inst/extdata/` の 8 ファイルは再取得不能な凍結バイト）
- 直接配布されている `wbgt_point_master-20260515.csv` の列構成が `wbgt_stations*.csv` と一致するか
- CSV 直リンク・`alert_record*.php` のパス体系が 2026 年度も同一か（PROVENANCE 問題 5）
- **WebAPI の `date_to` が包含か排他か**。仕様書に記載が無い。クライアントは境界を重ねて**どちらでも正しく**動くようにしてあるので実装はブロックされないが、判明すれば `@param date_to` に意味を書ける。1 本叩けば決まる: `getSurveyData?data_type=0&location_type=1&wbgt_nos=44132&date_from=20260901000000&date_to=20260901000000` の `count` が 1 なら包含、0 なら排他

**扱い**: 次に回す（`date_to` の確認は運用期間中＝2026-10-21 までに行う。それ以降は翌シーズンまで確かめられない）

## 7. provenance の到達性

#1 の調査で判明した 2 件のうち、1 件目は解消した。

- ~~**コピー元 `3b80b7a` がこの端末にしか無い**~~ — **解消（2026-09-03）**。japan-heatstroke は push 済みで、`origin/main`（`c3089c0`）から `3b80b7a` に到達できる。当初「未 push」と記録したのは push 前の時点を見ていたため
- **`SHA256SUMS` が `.Rbuildignore` されており、インストール後のユーザーは `inst/extdata/` を検証できない**。同梱するなら kumagusu の `inst/provenance/` 方式（パスを書き換えた複製）が必要。あわせて、グローバル指示にある**定期的な `shasum -c` の実行と provenance への追記**の運用も未設定

**扱い**: 1 件目は解消。2 件目（同梱と定期照合）は次に回す（#4 の前後で）

## 8. renv

**扱い: 完了（2026-09-04）** — `renv.lock`（114 パッケージ、`snapshot.type = "implicit"`）と `.Rprofile`・`_dependencies.R` を追加し、CI に `renv` / `renv-update` の 2 本を足した。方針の分担は `CLAUDE.md`「開発コマンド」の CI 節にある。

- **`R-CMD-check` の 6 ジョブは DESCRIPTION 解決のまま**（ユーザー判断）。lockfile へ寄せると `Depends: R (>= 4.1.0)` の下限を検証する唯一の手段（R 4.1 ジョブ）が壊れ、devel / oldrel の意味も失われる。`renv/activate.R` が追跡されている以上 `.Rprofile` は全ジョブで読まれるので、env の `RENV_CONFIG_AUTOLOADER_ENABLED: FALSE` が実際の分離を担っている。**消すと 6 ジョブすべてが黙って renv 経路に移る**
- **lockfile は `data-raw/` を含む**（ユーザー判断）。導出スクリプトは CRAN から外れた `ensurer` と `zipangu` に依存しており、その出所（GitHub の commit SHA）を書いている場所は repo 内で `renv.lock` だけ
- lockfile の健全性は確認済み: null フィールド 0、CRAN 由来は全て `Repository: "CRAN"`、`renv::status()` は synchronized

**残り**:

- ~~**`renv-update` はリポジトリ設定が要る。**~~ **解消（2026-09-04、ユーザーが有効化）**。「Allow GitHub Actions to create and approve pull requests」（Settings > Actions > General）を有効にした。`gh api repos/uribo/moewbgt/actions/permissions/workflow` が `can_approve_pull_request_reviews: true` を返すことで確認済み
- **同じ設定変更で `default_workflow_permissions` が `read` → `write` に変わっている。** 現行の 4 ワークフローはいずれも `permissions:` を明示しているので実害は無いが、既定値は「`permissions:` を書き忘れたワークフローに read-write のトークンを渡す」という意味になる。**扱い: 次に回す**（`read` に戻すかを決める。戻しても `renv-update` は `permissions: contents: write / pull-requests: write` を自分で宣言しているので動く）
- `renv` ジョブの `timeout-minutes: 45` はこのリポジトリでの実測が無い見積り。数回走ったら実測値で見直す（超えたら外さずに数字を上げる）。**扱い: 次に回す**

## 9. `.vscode` によるローカル限定の R CMD check NOTE

手元で `R CMD build .` → `R CMD check` を回すと `checking for hidden files and directories ... NOTE`（`Found the following hidden files and directories: .vscode`）が出る。**CI では出ない。**`.vscode` はユーザーのグローバル gitignore（`~/.config/git/ignore`）で除外されていて git に入らず、clean checkout からビルドする CI の tarball には現れないため。`CLAUDE.md` の「Status: OK（0/0/0）」は CI と同じ条件を指しており、その主張は今も有効。

**renv 導入による退行ではない**（2026-09-04 確認。根拠は `git ls-tree main` に `.vscode` が無いことと、`git check-ignore -v .vscode` が `~/.config/git/ignore` を指すこと。変更前のツリーを実際にビルドして比べたわけではない）。手元の NOTE を消したければ `.Rbuildignore` に `^\.vscode$` を 1 行足すだけだが、リポジトリの側の不具合ではない。

**扱い: 次に回す**（renv のスコープ外なので、この作業では触っていない）
