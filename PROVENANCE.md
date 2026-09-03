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

バイト一致は `SHA256SUMS` に記録してある。検証は次のコマンド:

```sh
shasum -a 256 -c SHA256SUMS
```

初回検証: 2026-09-03、13 ファイルすべて `OK`。

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
- **情報提供地点マスタが CSV で直接配布されている**: `https://www.wbgt.env.go.jp/man15NH/wbgt_point_master-20260515.csv`。PDF 表抽出に依存する理由は無くなる見込みだが、**列構成が `wbgt_stations*.csv` と一致するかは未確認**
- 過去年度版のマスタ CSV とマニュアル PDF が今も配布されているかは**未確認**。配布されていなければ `inst/extdata/` の 8 ファイルは再取得不能な凍結バイトになるため、**削除・上書きしない**
- 利用にあたっては**出典明記が必要**（電子情報提供サービスのページ）

## 引き継いだ既知の問題（コピー時点では未修正）

コピーは原文どおりで、以下はいずれも**このリポジトリで直す**課題として持ち込まれている。

1. **`data-raw/moe_wbgt_stations.R` の出力先が `here::here("data/…")` のまま**。CSV の置き場は `inst/extdata/` に変わったので、再実行しても読み込み側と揃わない
2. **`R/moe_alert.R` の `read_moe_alert <- memoise::memoise(...)` がトップレベルにある**。パッケージではインストール時にキャッシュが固定されてしまうため、`.onLoad()` の中で memoise する形に直す必要がある
3. **`wbgt_observe*.csv` の名前が内容と食い違う**（実況値ではなく都道府県ローマ字表）。かつ 2022〜2024 年版は同一バイト。旧 CSV サービス専用の遺物であり、API 移行後は不要になる可能性が高い
4. **単位の規約が未決着**。`getSurveyData` の `wbgt_WO` は `"26.7"` の小数、`getForecastData` の `forecast_val` は `"40"` `"-10"` で ×10 に見える。`parse_moe_wbgt_csv(file_type = "1-A")` も換算せず `col_double()` で読むだけ
5. **CSV 直リンク・`alert_record*.php` のパス体系が 2026 年度も同一かは未確認**
6. **`man/` が無い**。`NAMESPACE` は手書きなので `R CMD check` は undocumented exports で警告する
7. **`wbgt_guideline()` が整数以外で `NA` を返す区間がある**。`dplyr::between(x, 28, 30)` / `between(x, 25, 27)` で区切っているため、`27.5` や `30.5` はどの条件にも当たらない。境界は `>=` と `<` で連続にすべき
