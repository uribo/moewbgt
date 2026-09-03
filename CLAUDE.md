# CLAUDE.md

環境省 熱中症予防情報サイト（<https://www.wbgt.env.go.jp/>）の暑さ指数（WBGT）と熱中症警戒アラートを扱う R パッケージ。配布元 GitHub: `uribo/moewbgt`。CRAN 未登録。

このファイルはセッション開始時に読み込まれる一次知識源。経緯・出所・引き継いだ課題の詳細は [PROVENANCE.md](PROVENANCE.md) にあり、ここでは重複させずに参照する。

## 現在の状態（最初に読む）

**`R CMD check` は Status: OK**（0 errors / 0 warnings / 0 notes、2026-09-03 時点）。中身は [uribo/japan-heatstroke](https://github.com/uribo/japan-heatstroke) の `3b80b7a` からコピーした関数を出発点にしているが、以下は済んでいる: roxygen2 化と `man/` 生成、`NAMESPACE` の自動生成、`utils` の宣言。残る未整備:

- `tests/` は `wbgt_guideline()` の境界回帰テストだけ（testthat 3e、18 assertion）。ネットワークを叩く `read_moe_alert()` / `read_moe_wbgt()` は未カバーで、季節運用のためフィクスチャ（`httptest2` / `vcr`）が要る
- CI 未設置（`TODO.md` #3）
- 2026 年度に追加された **WebAPI に未対応**（現行コードは CSV 直リンク前提）

このパッケージの主目的は WebAPI クライアントの提供にある。API の制約（1 リクエスト 25,000 件上限、JMA 系 `pref_cd`、季節運用）は README.md の表と PROVENANCE.md に整理してある。**設計に着手する前にその 2 つを読む。**

引き継いだ既知の問題 7 件は [PROVENANCE.md](PROVENANCE.md) の「引き継いだ既知の問題」に番号付きで列挙してある。修正するときはその番号で参照し、内容をこちらに転記しない（二重管理を作らない）。

## SHA256SUMS の扱い（凍結バイト専用・失敗は常に異常）

`SHA256SUMS` は `inst/extdata/` の 8 ファイルだけを記録する。**不一致は例外なく異常**として扱う。

- 環境省の過去年度版マスタ CSV とマニュアル PDF が今も配布されているかは未確認で、配布されていなければ**再取得不能**
- **不一致を記録値の書き換えで解消しない。ファイルを削除・上書きしない。** 不一致は「上流または手元が変わった」という事実の報告であり、何が変わったかを確認してユーザーに報告する

```sh
shasum -a 256 -c SHA256SUMS
```

コピー時点のコード 5 ファイルのダイジェストは、かつて同じファイルに同居していたが `PROVENANCE.md` の履歴表へ移した（2026-09-03、TODO #1 決着）。**「コピー時に上流と一致した」は一度きりの主張**で、検証済みかつ初期コミット `7efd1b3` に凍結されている。以後コードを直せば当然一致しなくなるので、継続的な関門に混ぜない。同じ主張は git で自己検証できる:

```sh
git show 7efd1b3:R/guides.R | shasum -a 256
```

**`SHA256SUMS` にコード行を戻さない。** 関門が意図した変更に対して発砲するようになり、fail-loud の看板に例外規定を抱えさせることになる。

## 開発コマンド

```sh
Rscript -e 'roxygen2::roxygenise()'   # man/ と NAMESPACE を再生成
air format .
```

**`roxygenise()` は、パッケージがライブラリに入っていないと `[fn()]` 形式のリンクを解決できず**「Could not resolve link to topic」を出す。先に `R CMD INSTALL` してから `R_LIBS=<lib>` 付きで走らせれば消える（実体は未インストールが原因で、記述の誤りではない）。

**devtools はこの端末に入っていない。** テストは実際にインストールしてから流す。`.onLoad()` は `source()` や `load_all()` では発火しないので、memoise の確認にはインストールが要る:

```sh
R CMD INSTALL --library=/tmp/lib .
Rscript -e 'library(moewbgt, lib.loc = "/tmp/lib"); testthat::test_dir("tests/testthat", package = "moewbgt", stop_on_failure = TRUE)'
```

**R ファイル（`.R` / `.qmd`）を編集したら `air format .` を実行する。** `.claude/settings.json` の PostToolUse hook は Edit / Write ツール経由の編集にしか発火しないので、`sed` やヒアドキュメントで書き換えたときは手で走らせる。設定は `air.toml`（line-width 80）。

CI は未設置。`man/` が整い `R CMD check` が Status: OK になったので、jpops の `.github/workflows/{R-CMD-check,air-format}.yaml` を移植できる状態にある（`TODO.md` #3）。

## 構成

- `R/read_moe_wbgt.R` — 旧 CSV サービスの入口。`read_moe_wbgt()` が URL 組み立て（`moe_wbgt_request_url()`）とパース（`parse_moe_wbgt_csv()`）を束ねる
- `R/moe_alert.R` — 熱中症警戒アラート発表実績のスクレイピング（`read_moe_alert()`）と wide → long 変換（`alert_to_long()`）
- `R/guides.R` — WBGT 値 → 日常生活の指針（`wbgt_guideline()`）
- `R/moewbgt-package.R` — パッケージレベルの roxygen（`"_PACKAGE"`）と `utils::globalVariables()`。**副作用を持たせない**
- `man/` — roxygen2 の生成物。**直接編集しない**（`roxygenise()` で再生成する）
- `data-raw/moe_wbgt_stations.R` — 提供サービスマニュアル PDF から地点マスタを抽出する導出スクリプト。出力先は `inst/extdata/`。各ブロックの `file.exists()` ガードにより、**既にあるファイルは再実行しても上書きされない**（凍結バイトの保護はこのガードに依存している。外さない）。2020 年版の生成経路は記録されていない（PROVENANCE「元データの出自」）
- `data-raw/survey_tokyo2020.R` — オリパラ暑熱環境測定事業の資料取得。導出パイプラインの一部ではない
- `inst/extdata/` — 情報提供地点マスタ（`wbgt_stations*.csv`、840〜841 行）と都道府県ローマ字表（`wbgt_observe*.csv`、47 行）。**`wbgt_observe*` は実況値ではない**（名前と中身が食い違っている。PROVENANCE 問題 3）

### URL 体系（旧 CSV サービス）

`moe_wbgt_request_url()` はパスのプレフィックスで系統を分ける。ソース中のコメントが対応表を持っているので消さない。

| プレフィックス | 内容 |
| --- | --- |
| `prev15WG/dl/` | 予測値 |
| `est15WG/dl/` | 実況値（当年度） |
| `mntr/dl/` | 実測地点別（11 地点、`station` 引数の大文字ローマ字名） |
| `mntr/final/{year}/` | 過去年度の確定値 |

分岐は `type` × どの引数が `NULL` でないか、で決まる。**どの条件にも当たらないと関数は暗黙に `NULL` を返す**（`else` 節が無い）。ここを触るときは jpops と同様に末尾へ `else` を置き、想定外の入力で黙って `NULL` を返さないようにする。

`parse_moe_wbgt_csv()` の `file_type` は仕様書のファイル種別（`1-A`〜`2-D`）に対応する。`2-A` と `2-D` は引数が `NULL` のときファイル名から地点を復元するので、URL でもローカルパスでも動く。**2026 年度もこのパス体系が同一かは未確認**（PROVENANCE 問題 5）。

### 単位の規約が未決着

`getSurveyData` の `wbgt_WO` は `"26.7"` の小数、`getForecastData` の `forecast_val` は `"40"` `"-10"` で ×10 に見える。`parse_moe_wbgt_csv(file_type = "1-A")` は換算せず `col_double()` で読むだけ。API クライアントを書くときに公開出力の単位を決め、決めた根拠をここに書く（PROVENANCE 問題 4）。

## コーディング規約

- パイプは `|>`。`Depends: R (>= 4.1.0)`
- フォーマッタは air（上記）。変数名・列名は英語のみ、散文は日本語でよい
- **`R/` の日本語文字列リテラルは Unicode エスケープで書く**（`"危険"` ではなく `"\u5371\u967a"` の形）。R CMD check の非 ASCII 警告を避けるため。**現在 `R/` に生の日本語リテラルは無い**（残る非 ASCII は `R/read_moe_wbgt.R` のコメントだけで、コメントは check の対象外）。新しく足すときも同じ形で書く。`data-raw/` は `.Rbuildignore` されるので生のままでよい
- **roxygen の散文に日本語を書かない。** `.Rd` では `\u5371\u967a` が escape として解釈されず literal に出るため、エスケープ回避と可読性が両立しない。英語で書く
- **データマスキング／tidyselect で参照する列名は `R/moewbgt-package.R` の `utils::globalVariables()` に足す**（各関数冒頭の `col <- NULL` 方式は採らない。jpops は NULL 代入、kumagusu は globalVariables で流儀が割れているが、このパッケージは後者に寄せて 1 か所に集める）。裸の tidyselect ヘルパーは `tidyselect::contains()` のように修飾して、globalVariables では隠さない
- テストの期待値は実装側の定数を参照せず Unicode エスケープで直書きする。実装と同じ転記ミスを共有させないため（kumagusu / jpops と同じ規約）
- ユーザー向け関数はエクスポートし roxygen2 ドキュメントを書く。内部関数には書かない
- **`R/moe_alert.R` の `@importFrom rvest read_html` を「`rvest::` があるから冗長」と消さない。** `.onLoad()` が `read_moe_alert` を memoise 版へ再束縛するため、インストール後の名前空間を見る R CMD check からは `rvest::` の呼び出しが見えなくなり、消すと「All declared Imports should be used」の NOTE が復活する（2026-09-03 に再束縛を外して確認済み）。理由は当該行の直上コメントにも書いてある
- 取得処理を `purrr::safely()` や `tryCatch()` で包んで失敗を握り潰さない。fail-loud のまま保つ
- `dplyr::select()` / `rename()` の位置指定（`dplyr::select(!2)`、`seq.int(2, ncol(df) - 1)` など）は上流 CSV のヘッダーが年度・種別で揺れるための意図的なもの。列名ベースに「直さない」

## エージェント環境

- `.claude/settings.json` — env（`R_ENVIRON_USER` とロケール）、資格情報ファイルの読み書き拒否、air の PostToolUse hook。**意図的に git 追跡している**（`.claude/settings.local.json` は追跡しない）
- `.claude/skills/`、`.agents/skills/` — conf-macos の `deploy/manifest.tsv` で宣言的に配備した symlink（`r-modern-tidyverse`, `r-rlang-programming`）。手動 `ln -s` はしない。中身は gitignore され、`.gitignore` 自身だけが追跡される
- `.codex/config.toml` — Codex の sandbox・環境変数ポリシー
- `AGENTS.md` — Codex 固有の補足規約（本ファイルへのポインタ + 資格情報の扱い + 引き継ぎ手順）
- `memory/project-status.md` の「引き継ぎ（HANDOFF）」欄 — Claude ↔ Codex の引き継ぎはこの欄を経由する。方針を決めた時・試行を捨てた時・検証を実行した時・セッションを終える時に更新する
- `TODO.md` — 未決着の判断と次に行う作業。GitHub Issue はまだ使っていない

`R_ENVIRON_USER=/dev/null` は資格情報を子プロセスに渡さないための設定だが、R はプロジェクト直下の環境ファイルを *user* 側として扱うため**プロジェクトの分ごと無効化する**。ロケールの固定をそこに頼れないので、`LC_COLLATE=C` / `LC_TIME=C` は `.claude/settings.json` と `.codex/config.toml` の両方に直接書いてある。**`LC_ALL` に統合しない**（`LC_CTYPE` まで上書きされ、`prefecture == "沖縄県"` のような比較が無警告で行を落とす）。

## コミット

Conventional Commits に従う（`/commit-msg` スキル参照）。`Co-Authored-By:` フッタは付けない。ステージングは `git add -u` かパス明示で行う（`git add -A` は使わない）。
