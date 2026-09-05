# moewbgt

環境省 熱中症予防情報サイト（<https://www.wbgt.env.go.jp/>）が提供する暑さ指数（WBGT）と熱中症警戒アラートのデータを R で扱うためのパッケージ。

> [!NOTE]
> **WebAPI クライアントを追加しました**（`read_moe_forecast()` / `read_moe_survey()`）。旧 CSV 直リンク向けの関数（[uribo/japan-heatstroke](https://github.com/uribo/japan-heatstroke) からのコピー）も残しています。経緯と既知の問題は [PROVENANCE.md](PROVENANCE.md) を参照してください。

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

このパッケージの主目的は、この API のクライアントを提供することです。設計上の要点は次のとおりです。

- **25,000 件上限**。上限に達したかどうかは行数を事前に見積もらず、上限エラーを受けてから期間を再帰的に二分して対処します（下限 1 時間）。全地点を長期間取るときは `max_span` で先に割ってください
- **リクエストの境界は 1 点重ねます。** 上流が `date_to` を包含として扱うか排他として扱うかは仕様書に書かれていません。生きた API に照会した結果は**両端とも包含**でした（2026-09-04、[PROVENANCE.md](PROVENANCE.md)「上流の状況」）が、これは実測であって仕様の保証ではありません。重ねておけば、包含なら重複を落とすだけ、排他なら後続のリクエストが拾うので、**どちらでも分割の有無で結果が変わりません**
- **`pref_cd` は JMA 系のコード体系**で JIS コードではありません（北海道は振興局で 11〜24 に分割、沖縄は `9194`）。対応表は `wbgt_pref_codes` として同梱しています
- **単位が 2 つのエンドポイントで違い、換算はしません。** `getSurveyData` の `wbgt_WO` / `wbgt_Tw` / `wbgt_Tg` は摂氏の小数（`"21.9"`）ですが、`getForecastData` の `forecast_val` は**摂氏 ×10 の整数**（`"220"` = 22.0 ℃）です。仕様書はどちらの単位も書いていないので、生きた API に照会して確定させました（[PROVENANCE.md](PROVENANCE.md) 問題 4）。値は上流のキー名のまま返すので、換算は利用側で行ってください。なお仕様書が「数値」と書くフィールドの多くは JSON では文字列で返ります
- `getSurveyData` の `data_type` は 0（実況推定値）/ 1（実況実測値）。`wbgt_WI`（データ品質情報 0〜4）は欠測補完の有無を示すので落としません

```r
# 予測値（特定の発表時刻）
read_moe_forecast(station_no = 44132, origin_date = "2026-09-01 00:00:00")

# 実況値（期間指定）
read_moe_survey(
  station_no = 44132,
  date_from = "2026-09-01",
  date_to = "2026-09-02"
)

# 都道府県コードの対応表
wbgt_pref_codes
```

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

地点マスタと地方・都道府県コードの対応表はデータセットとして同梱しています。`library(moewbgt)` のあと名前で参照できます。

```r
# 情報提供地点のマスタ（865 地点 = 稼働中 841 + 提供終了 24）
wbgt_stations

# 稼働中の実測地点だけを取る
dplyr::filter(wbgt_stations, !is.na(measure_start_date), is.na(measure_end_date))

# WebAPI の返り値に地点名・緯度経度を付ける（返り値も area_cd / pref_cd を持つので必要な列だけ結合する）
read_moe_survey(station_no = 44132, date_from = "2026-09-01", date_to = "2026-09-02") |>
  dplyr::left_join(
    dplyr::select(wbgt_stations, station_no, station_name, latitude, longitude),
    by = dplyr::join_by(wbgt_no == station_no)
  )

# WebAPI の地方コード・都道府県コード（JMA 系。JIS コードではありません）
wbgt_pref_codes
```

| データセット | 中身 | 行数 |
|---|---|---|
| `wbgt_stations` | 情報提供地点のマスタ。`station_no` は WebAPI の `wbgt_no` と同じ整数（旧 CSV サービスの返り値は文字列なので結合時に揃える）、`area_cd` / `pref_cd` は WebAPI が受け付けるコード。緯度経度は 10 進度、提供終了日などの `9999-99-99`（継続中）は `NA` | 865 |
| `wbgt_pref_codes` | 地方コード・都府県／振興局コードの対応表 | 60 |

`wbgt_stations` の導出元は環境省が直接配布する[地点マスタ CSV](https://www.wbgt.env.go.jp/man15NH/wbgt_point_master-20260515.csv) で、そのバイトは `inst/extdata/wbgt_point_master-20260515.csv` に凍結してあります（上流は掲載日入りの 1 本だけで、前年度版は既に取得できません）。

### 旧バージョンの参照テーブル（`inst/extdata/`）

提供サービスマニュアル PDF から抽出した年度別のマスタも残してあります。上流の PDF は現在 403 で取り直せないため、年度スナップショットとして保存しているものです。**新しく書くコードは `wbgt_stations` を使ってください。**

```r
readr::read_csv(
  system.file("extdata", "wbgt_stations2024.csv", package = "moewbgt"),
  col_types = "cccc"
)
```

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
