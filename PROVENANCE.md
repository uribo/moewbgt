# PROVENANCE

このリポジトリの初期内容は、既存リポジトリ **[uribo/japan-heatstroke](https://github.com/uribo/japan-heatstroke)** から**コピー**して作成した。git 履歴は移していない（`git filter-repo` / `git subtree split` は使っていない）。元の履歴を辿る必要が生じたら japan-heatstroke 側を参照する。

- **コピー元リポジトリ**: `uribo/japan-heatstroke`
- **コピー元コミット**: `3b80b7aa3eb8e13b36d5e1266c5e3f0910f71bbb`（`3b80b7a` / `docs: add TODO.md for open questions about the tracked data files`）
- **コピー日**: 2026-09-03（JST）
- **コピー方法**: `cp` によるバイト単位の複製。内容は一切改変していない

分割の理由: 2026 年度から環境省 熱中症予防情報サイトに WebAPI が追加され、環境省分は「仕様書のあるバージョン付き API のクライアント」になった。1 リクエスト 25,000 件の上限に対する期間分割・リトライ、運用期間外でも通るフィクスチャテスト、JMA 系 `pref_cd` の対応表が必要で、`source()` する関数集の枠に収まらないため。線引きは提供元で行い、消防庁・厚生労働省分は japan-heatstroke に残した。

## ファイル対応表

| コピー元（japan-heatstroke） | コピー先（moewbgt） |
|---|---|
| `R/read_moe_wbgt.R` | `R/read_moe_wbgt.R` |
| `R/moe_alert.R` | `R/moe_alert.R` |
| `R/guides.R` | `R/guides.R` |
| `data-raw/moe_wbgt_stations.R` | `data-raw/moe_wbgt_stations.R` |
| `data-raw/survey_tokyo2020.R` | `data-raw/survey_tokyo2020.R` |
| `data/wbgt_stations{2020,2022,2023,2024}.csv` | `inst/extdata/wbgt_stations{2020,2022,2023,2024}.csv` |
| `data/wbgt_observe{2020,2022,2023,2024}.csv` | `inst/extdata/wbgt_observe{2020,2022,2023,2024}.csv` |
| `air.toml`, `.gitignore` | 同名（設定ファイルとして流用） |

**`data/` → `inst/extdata/` へ移した理由**: R パッケージの `data/` は `.rda` を置く場所であり、CSV をそのまま置く場所ではない。読み込み方は README を参照。

## 2 種類の記録を分けてある

コピー当初、`SHA256SUMS` は 13 ファイル（コード 5 + `inst/extdata/` 8）を一括で記録していた。しかしこの 2 つは**時間的な性質が違う**。

- **`inst/extdata/` の 8 ファイル = 継続する不変条件**。上流から再取得できない可能性があり、今後も変わってはいけない。git はコミットされた変更を黙って記録するが `shasum -c` は止まるので、**コミットでは素通りする改変を止める関門**として機能する
- **コード 5 ファイル = 一度きりの主張**。「コピー時点で japan-heatstroke と一致した」という事実は 2026-09-03 に検証して確定した。以後このリポジトリでコードを直せば当然に一致しなくなる

一度きりの主張を継続的な関門と同じファイルに置くと、「`shasum -c` の失敗＝異常」という単純な運用ができなくなる。そこで**コード 5 行を `SHA256SUMS` から外し、下記の履歴表に移した**（2026-09-03）。

**現在の `SHA256SUMS` は凍結バイト専用であり、失敗は常に異常である。**

```sh
shasum -a 256 -c SHA256SUMS   # 8 ファイル。初回検証 2026-09-03、すべて OK
```

### コピー時点のコードのダイジェスト（履歴・検証済み・更新しない）

コピー直後の 5 ファイル。2026-09-03 に `shasum -a 256 -c` で全件 `OK` を確認した時点の値であり、**現在のファイルと一致する必要はない**。

| ファイル | sha256（コピー時点） |
|---|---|
| `R/guides.R` | `754714f4dbb832a1ef1445c3140c12e73b73a6af988f6a0efd5b3a83ad934880` |
| `R/moe_alert.R` | `393ce42f5804499b0f1c6c6c90392274957be11751f14ea6322c088ebc000197` |
| `R/read_moe_wbgt.R` | `2f88bb73a14603637cbd4b7f0646e7081788d6f3f8bcd0f8ba21ac0edb338d37` |
| `data-raw/moe_wbgt_stations.R` | `706b0ce2e1abd62777c31fddbbd93009e58796f4bb8feb088ad8da0fdc041e99` |
| `data-raw/survey_tokyo2020.R` | `322d4b259c7ab09d2f8e5c89b65fcd40764aa868b8da6d7ba005b496dd301c76` |

この表は参照用で、**再検証の必要は無い**。同じ値はこのリポジトリの初期コミット `7efd1b3` が保持しており（2026-09-03 に 13/13 一致を確認済み）、そちらは自己検証的だからである:

```sh
git show 7efd1b3:R/guides.R | shasum -a 256
```

### 上流コミットの到達性（解消済み）

コピー元の `3b80b7a` は `uribo/japan-heatstroke` の `origin/main`（`c3089c0`）から到達できる。2026-09-03 に push され、GitHub API でも解決する。

一時期この節は「ローカルクローンにしか存在しない」と書いていたが、それは push 前の時点の観測だった。moewbgt 側のバイトは `7efd1b3` が push 済みなので、上流・下流とも 1 台依存ではない。

## 元データの出自

`inst/extdata/` の 8 ファイルは**観測値ではなく参照テーブル**である。

| ファイル | 中身 | 行数 |
|---|---|---|
| `wbgt_stations{2020,2022,2023,2024}.csv` | 情報提供地点のマスタ（`area`, `station_no`, `station_name`, `pref_code`） | 840〜841 |
| `wbgt_observe{2020,2022,2023,2024}.csv` | 実況値ではなく**都道府県名 → ローマ字表記の対応表**（`prefecture`, `roman`）。旧 CSV サービスの URL 組み立て用 | 47 |

2022・2023・2024 年版は `data-raw/moe_wbgt_stations.R` が環境省の提供サービスマニュアル PDF（`https://www.wbgt.env.go.jp/man15NH/R0{4,5,6}_wbgt_data_service_manual.pdf`）から表を抽出して生成したもの。行数は `ensurer::ensure()` / `assertr::verify()` で 841・840・47 に固定されている。**2020 年版の 2 ファイルは同スクリプトの対象外で、生成経路が記録されていない。**

`wbgt_observe2022.csv` / `wbgt_observe2023.csv` / `wbgt_observe2024.csv` は **sha256 が完全に一致する**（`5005e76e…`）。都道府県名とローマ字の対応が 3 年間変わっていないためで、年次で分ける意味は実質的に無い。

## 上流の状況（2026-09-03 確認）

- 熱中症予防情報サイトのデータ提供は**季節運用**であり、終了していない。2024-10-23 は 2024 年度の運用末日。[電子情報提供サービス](https://www.wbgt.env.go.jp/data_service.php)は 2026 年度も 2026-10-21 まで提供
- 2026 年度から **WebAPI** が追加された（[API 仕様書 第 1.1 版](https://www.wbgt.env.go.jp/man15NH/wbgt_data_api_service_manual.pdf)、令和 8 年 6 月 24 日掲載）。実況値 2010 年以降、予測値 2021 年以降
    - **取得スクリプト**: `data-raw/wbgt_api_manual.R`（`usethis::use_data_raw("wbgt_api_manual")` で作成）。第 1.1 版と第 1.0 版の 2 本を `data-raw/` へ落とす。置き場所と命名は `data-raw/moe_wbgt_stations.R` が提供サービスマニュアル PDF を落とすのと同じ規約（上流のファイル名そのまま、`data-raw/` 直下、`file.exists()` ガードで既存ファイルを上書きしない）。取得後に sha256 を下表と照合し、**一致しなければ `stop()` する**。2-1 節の地方コード・都道府県コード表を抽出するときは、この下に `pdftools::pdf_text()` の処理を足す

        | 版 | 上流ファイル名 | 性質 | サイズ | sha256 |
        |---|---|---|---|---|
        | 1.1（令和 8 年 6 月 24 日掲載） | `wbgt_data_api_service_manual.pdf` | 現行版を指す**動く URL** | 393,925 | `a29848c1fdab3d756261f548601741cadf8973c05fe2e6d0754fd2b4efdbc105` |
        | 1.0（令和 8 年 4 月 22 日掲載） | `wbgt_data_api_service_manual_r080422.pdf` | 掲載日入りの**不変 URL** | 251,834 | `18b35833db0ec2651d3201f69b8484602826caf40516c597b281052d624745ed` |

    - **上流の URL は 2 系統ある**（2026-09-03 確認）。版なしの URL は現行版を指し、新しい版が出れば中身が入れ替わる。掲載日入りの URL は第 1.0 版に対しては存在するが、現行の第 1.1 版に対応する `_r080624.pdf` は**存在しない**。つまり掲載日入りの複製は現行版ではなく**旧版に対して作られている**（差し替え時にアーカイブされる）ように見える。この読みが正しければ第 1.1 版も差し替え時に `_r080624.pdf` として残るが、**確認できるのは第 1.2 版が出た後**である
    - `data-raw/` は `.Rbuildignore` され、`.gitignore` の `*.pdf` により追跡もされない。したがって**この 2 本は fresh clone や別セッションには存在しない**。手元に無ければ上記スクリプトで取り直す。**追跡しない判断（2026-09-03、ユーザー）**: 仕様書は解析データではなく、取得スクリプトと sha256 の記録があれば再取得できるため。`.gitignore` に例外を足さない
- **情報提供地点マスタが CSV で直接配布されている**: `https://www.wbgt.env.go.jp/man15NH/wbgt_point_master-20260515.csv`。PDF 表抽出に依存する理由は無くなる見込みだが、**列構成が `wbgt_stations*.csv` と一致するかは未確認**
- 過去年度版のマスタ CSV とマニュアル PDF が今も配布されているかは**未確認**。配布されていなければ `inst/extdata/` の 8 ファイルは再取得不能な凍結バイトになるため、**削除・上書きしない**
- 利用にあたっては**出典明記が必要**（電子情報提供サービスのページ）

## 引き継いだ既知の問題（コピー時点では未修正）

コピーは原文どおりで、以下はいずれも**このリポジトリで直す**課題として持ち込まれている。取り消し線の項目は解消済み。残るのは 5（パス体系の確認、TODO #6）だけで、3 は改名しない判断、4 は実測で決着している。

1. ~~**`data-raw/moe_wbgt_stations.R` の出力先が `here::here("data/…")` のまま**~~ — **解消（2026-09-03）**。出力先を `inst/extdata/` に変更した（12 箇所）。各ブロックの `file.exists()` ガードは残してあるので、再実行しても既存の凍結バイトは上書きされない
2. ~~**`R/moe_alert.R` の `read_moe_alert <- memoise::memoise(...)` がトップレベルにある**~~ — **解消（2026-09-03）**。素の関数定義に戻し、同ファイル末尾の `.onLoad()` で memoise するようにした。インストール後に `memoise::is.memoised(read_moe_alert)` が `TRUE` を返すことを確認済み
3. **`wbgt_observe*.csv` の名前が内容と食い違う**（実況値ではなく都道府県ローマ字表）。かつ 2022〜2024 年版は同一バイト。旧 CSV サービス専用の遺物であり、API 移行後は不要になる可能性が高い — **改名しない判断（2026-09-03、ユーザー）**。公開リポジトリの破壊的変更であり、API 移行でファイルごと不要になりうるため。食い違いは記述で担保する（本表・`README.md`・`CLAUDE.md`）
4. ~~**単位の規約が未決着**~~ — **解消（2026-09-03）**。生きた API に照会して確定した。`getSurveyData` の `wbgt_WO` / `wbgt_Tw` / `wbgt_Tg` は**摂氏の小数**、`getForecastData` の `forecast_val` は**摂氏 ×10 の整数**。仕様書はどちらの単位も書いていない。裏づけは東京（`wbgt_no` 44132）の 2026-09-01 で、`getSurveyData` の 00:00 が `wbgt_WO` = `"21.9"`、同日の `getForecastData` が 03:00 に `forecast_val` = `"220"`、09:00 に `"260"`、12:00 に `"280"` を返す（22.0 / 26.0 / 28.0 ℃ で、9 月初旬の朝→正午の推移として整合する）。2024-08-05 でも同じ形式。クライアントは**換算せず上流のキー名のまま返す**方針なので（TODO #4）、この単位はドキュメントで伝える。なお仕様書が「数値」と書くフィールドの多くは JSON では文字列で返り、整数で返るのは `wbgt_no` / `wbgt_class` / `area_cd` / `pref_cd` / `flag` だけ。旧 CSV サービスの `parse_moe_wbgt_csv(file_type = "1-A")` は換算せず `col_double()` で読むだけで、**そちらの単位は未確認**
5. **CSV 直リンク・`alert_record*.php` のパス体系が 2026 年度も同一かは未確認**
6. ~~**`man/` が無い**~~ — **解消（2026-09-03）**。7 つの export に roxygen コメントを書いて `man/` を生成し、`NAMESPACE` を roxygen2 生成に置き換えた。`R CMD check` は Status: OK
7. ~~**`wbgt_guideline()` が整数以外で `NA` を返す区間がある**~~ — **解消（2026-09-03）**。降順の `>=` 連鎖に置き換え、指針の帯を半開区間として連続させた。旧実装は 15〜40 を 0.1 刻みで走らせると 18 点が `NA` になっていた。回帰テストは `tests/testthat/test-guides.R`
