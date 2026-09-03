# moewbgt

環境省 熱中症予防情報サイト（<https://www.wbgt.env.go.jp/>）が提供する暑さ指数（WBGT）と熱中症警戒アラートのデータを R で扱うためのパッケージ。

> [!WARNING]
> **移行直後の状態です。** 中身は [uribo/japan-heatstroke](https://github.com/uribo/japan-heatstroke) からコピーした関数そのままで、**2026 年度に追加された WebAPI にはまだ対応していません**（CSV 直リンクを前提としたコードです）。ドキュメント（`man/`）も未整備で、`R CMD check` は通りません。経緯と既知の問題は [PROVENANCE.md](PROVENANCE.md) を参照してください。

## 状況

環境省 熱中症予防情報サイトのデータ提供は**季節運用**です。「2024-10-23 に提供終了」という記述を見かけますが、これは 2024 年度の運用末日であって終了ではありません。2026 年度は 2026-10-21 まで提供されています（[電子情報提供サービス](https://www.wbgt.env.go.jp/data_service.php)、確認日 2026-09-03）。

2026 年度から **WebAPI** が追加されました（[API 仕様書 第 1.1 版](https://www.wbgt.env.go.jp/man15NH/wbgt_data_api_service_manual.pdf)）。

| 項目 | 内容 |
|---|---|
| エンドポイント | `GET https://www.wbgt.env.go.jp/api/v1/getForecastData` / `getSurveyData` |
| 認証 | 不要（API キーなし） |
| レスポンス | JSON |
| 対象期間 | 実況値 2010 年以降、予測値 2021 年以降 |
| 上限 | **1 リクエスト 25,000 件**。超過時はデータを返さず `status: "error"` |

このパッケージの主目的は、この API のクライアントを提供することです。実装にあたっては次が論点になります。

- **25,000 件上限**。全地点 1 時間値は 841 × 24 = 20,184 件/日なので、`location_type=3` は日単位でしか取れない。期間分割・再結合・リトライがクライアントの本体になる
- **`pref_cd` は JMA 系のコード体系**で JIS コードではない（北海道は振興局で 11〜24 に分割、沖縄は `9194`）。対応表なしに都道府県名へ変換しない
- **季節運用**なので、生きた API を叩くテストは運用期間外に落ちる。`httptest2` / `vcr` のフィクスチャが前提
- `getSurveyData` の `data_type` は 0（実況推定値）/ 1（実況実測値）。`wbgt_WI`（データ品質情報 0〜4）は欠測補完の有無を示すので落とさない

## インストール

```r
# pak::pak("uribo/moewbgt")
```

## 使い方（移行前の関数、CSV 直リンク前提）

```r
# 予測値（地点別）
read_moe_wbgt(type = "forecast", station_no = "43056")

# 実況値（地点別・年月指定）
read_moe_wbgt(type = "observe", station_no = "43056", year_month = "202404")

# ダウンロード済みファイルのパース
parse_moe_wbgt_csv("yohou_43056.csv", file_type = "1-A")

# 熱中症警戒アラートの発表実績
df <- read_moe_alert(2024)
alert_to_long(df, 2024)

# WBGT 値を日常生活の指針に変換
wbgt_guideline(31)
```

## 同梱データ

情報提供地点のマスタと、旧 CSV サービスの URL 組み立てに使う都道府県ローマ字表を `inst/extdata/` に同梱しています。**japan-heatstroke では `data/` にありましたが、R パッケージの `data/` は `.rda` を置く場所なので移しました。**読み込みパスが変わります。

```r
# 旧（japan-heatstroke）
# readr::read_csv("data/wbgt_stations2024.csv", col_types = "cccc")

# 新（moewbgt）
readr::read_csv(
  system.file("extdata", "wbgt_stations2024.csv", package = "moewbgt"),
  col_types = "cccc"
)
```

いずれも観測値ではなく参照テーブルです。**ファイル名と中身は 1 か所ずれています**:

| ファイル | 中身 | 行数 |
|---|---|---|
| `wbgt_stations{2020,2022,2023,2024}.csv` | 情報提供地点のマスタ（`area`, `station_no`, `station_name`, `pref_code`） | 840〜841 |
| `wbgt_observe{2020,2022,2023,2024}.csv` | **実況値ではありません。**都道府県名 → ローマ字表記の対応表（`prefecture`, `roman`）で、旧 CSV サービスの URL 組み立て用 | 47 |

`wbgt_observe*` を改名しないのは、公開リポジトリの破壊的変更になるうえ、WebAPI へ移行するとこのファイル自体が不要になる可能性が高いためです（2026-09-03 の判断）。内容と出自は [PROVENANCE.md](PROVENANCE.md) を参照してください。

## このパッケージが扱わないもの

消防庁「熱中症による救急搬送人員」と厚生労働省 人口動態統計は [uribo/japan-heatstroke](https://github.com/uribo/japan-heatstroke) に残しています。提供元で分けているためです。

## 出典

データの利用にあたっては出典の明記が必要です（[電子情報提供サービス](https://www.wbgt.env.go.jp/data_service.php)）。

## ライセンス

コードは [MIT](LICENSE.md)。同梱データの利用条件は環境省のデータ提供ページに従います。
