####################################
# 環境省 情報提供地点マスタ (直接配布 CSV) → data/wbgt_stations.rda
#
# 2026年度は地点マスタが CSV で直接配布されている。掲載日入りの URL が
# 1本あるだけで、過去年度版 (wbgt_point_master-20250515.csv) は 404 を返す
# (2026-09-05 確認)。年度が替わればファイル名が変わり旧版は消える見込み
# なので、取得したバイトは inst/extdata/ に凍結し SHA256SUMS で守る。
#
# 従来の inst/extdata/wbgt_stations*.csv は提供サービスマニュアル PDF から
# pdftools で抽出していたが、その PDF は上流が 403 になっている
# (PROVENANCE.md「上流の状況」)。配布 CSV は旧 841 地点を全て含む上位互換
# なので、以後の地点マスタはこちらを典拠にする。既存の8ファイルは再取得
# 不能な凍結バイトなので削除せず、年度スナップショットとして残す。
#
# 配布 CSV の865行 = 稼働中841 + 終了済み24。終了地点も過去データとの結合に
# 要るので落とさない。
####################################

point_master_file <- "wbgt_point_master-20260515.csv"
point_master_url <- paste0(
  "https://www.wbgt.env.go.jp/man15NH/",
  point_master_file
)
point_master_sha256 <-
  "684fd9b005eac994bed219d042e6b80f4444ab7896537078b0ce3b0ad4a0c5a4"

point_master_path <- here::here("inst", "extdata", point_master_file)

# 既にあるファイルは上書きしない (moe_wbgt_stations.R と同じガード)
if (!file.exists(point_master_path)) {
  download.file(point_master_url, destfile = point_master_path, mode = "wb")
}

# 上流の差し替え・手元の破損を fail-loud で拾う。記録値の書き換えで黙らせ
# ない。掲載日入りの URL は中身が変わらない前提なので、不一致は異常。
observed_sha256 <- digest::digest(
  point_master_path,
  algo = "sha256",
  file = TRUE
)
if (!identical(observed_sha256, point_master_sha256)) {
  stop(
    glue::glue(
      "地点マスタ CSV の sha256 が記録値と一致しない。\n",
      "  path:     {point_master_path}\n",
      "  expected: {point_master_sha256}\n",
      "  observed: {observed_sha256}\n",
      "SHA256SUMS と PROVENANCE.md 「上流の状況」の節を参照。"
    )
  )
}

# 列の並びが変わっていないことを見てから位置で改名する。ヘッダーを英語名に
# 読み替えるだけだと、上流が列を入れ替えたときに黙って別の列を読む。
expected_header <- c(
  "地方",
  "振興局",
  "地点番号",
  "観測所名",
  "よみがな",
  "ローマ字表記",
  "所在地",
  "Latitude",
  "Latitude_3",
  "Longitude",
  "Longitude_4",
  "Start Year-Start Month-Start Day",
  "End Year-End Month-End Day",
  "Old Station Number",
  "実測開始日",
  "実測終了日",
  "特別警戒情報判定除外開始日",
  "特別警戒情報判定除外終了日"
)

df_point_master <-
  readr::read_csv(
    point_master_path,
    col_types = readr::cols(.default = readr::col_character()),
    trim_ws = TRUE
  )

if (!identical(names(df_point_master), expected_header)) {
  stop("地点マスタ CSV のヘッダーが記録した並びと一致しない。")
}

names(df_point_master) <- c(
  "area_name",
  "pref_name",
  "station_no",
  "station_name",
  "kana",
  "romaji",
  "address",
  "latitude_deg",
  "latitude_min",
  "longitude_deg",
  "longitude_min",
  "start_date",
  "end_date",
  "old_station_no",
  "measure_start_date",
  "measure_end_date",
  "special_alert_exclusion_start_date",
  "special_alert_exclusion_end_date"
)

# 上流は「継続中」を 9999-99-99 で表す。Date に載らない番人値なので NA に
# 倒す。該当しない行 (実測地点でない等) は readr が既に NA にしている。
parse_master_date <- function(x) {
  as.Date(dplyr::na_if(x, "9999-99-99"), format = "%Y-%m-%d")
}

# 緯度経度は度と分の2列に分かれている。分は10進度へ畳む (度 + 分/60)。
# 分が60以上なら列の意味を取り違えているので止める。
degrees_minutes_to_decimal <- function(degrees, minutes) {
  degrees <- as.numeric(degrees)
  minutes <- as.numeric(minutes)
  if (anyNA(degrees) || anyNA(minutes)) {
    stop("緯度経度に欠損がある。")
  }
  if (any(minutes < 0 | minutes >= 60)) {
    stop("緯度経度の分が 0 以上 60 未満の範囲に収まらない。")
  }
  degrees + minutes / 60
}

wbgt_pref_codes <- local({
  env <- new.env()
  load(here::here("data", "wbgt_pref_codes.rda"), envir = env)
  env$wbgt_pref_codes
})

wbgt_stations <-
  df_point_master |>
  dplyr::mutate(
    station_no = as.integer(station_no),
    old_station_no = as.integer(old_station_no),
    latitude = degrees_minutes_to_decimal(latitude_deg, latitude_min),
    longitude = degrees_minutes_to_decimal(longitude_deg, longitude_min),
    dplyr::across(
      c(
        start_date,
        end_date,
        measure_start_date,
        measure_end_date,
        special_alert_exclusion_start_date,
        special_alert_exclusion_end_date
      ),
      parse_master_date
    )
  ) |>
  dplyr::left_join(
    wbgt_pref_codes,
    by = dplyr::join_by(area_name, pref_name),
    relationship = "many-to-one",
    unmatched = "error"
  ) |>
  dplyr::select(
    area_cd,
    area_name,
    pref_cd,
    pref_name,
    station_no,
    station_name,
    kana,
    romaji,
    address,
    latitude,
    longitude,
    start_date,
    end_date,
    old_station_no,
    measure_start_date,
    measure_end_date,
    special_alert_exclusion_start_date,
    special_alert_exclusion_end_date
  ) |>
  dplyr::arrange(station_no)

if (nrow(wbgt_stations) != 865L) {
  stop("地点マスタは865行でなければならない。")
}
if (anyDuplicated(wbgt_stations$station_no) != 0L) {
  stop("地点番号が重複している。")
}
if (anyNA(wbgt_stations$start_date)) {
  stop("提供開始日に欠損がある。")
}
if (sum(is.na(wbgt_stations$end_date)) != 841L) {
  stop("稼働中 (提供終了日が 9999-99-99) の地点は841でなければならない。")
}
if (sum(!is.na(wbgt_stations$measure_start_date)) != 49L) {
  stop("実測地点は49 (うち稼働中47) でなければならない。")
}
if (
  sum(
    !is.na(wbgt_stations$measure_start_date) &
      is.na(wbgt_stations$measure_end_date)
  ) !=
    47L
) {
  stop("稼働中の実測地点は47でなければならない。")
}
if (
  !all(dplyr::between(wbgt_stations$latitude, 20, 46)) ||
    !all(dplyr::between(wbgt_stations$longitude, 122, 154))
) {
  stop("緯度経度が日本の範囲に収まらない。")
}

# 仕様書 2-1節の都府県・振興局と配布 CSV の振興局は表記まで一致する
# (「ｵﾎｰﾂｸ」の半角カナを含む)。旧 wbgt_stations*.csv は同じ列を
# 「網走・北見・紋別」と書いていたので、その差は配布 CSV では消えている。
if (!setequal(wbgt_stations$pref_name, wbgt_pref_codes$pref_name)) {
  stop("配布 CSV の振興局名が仕様書の都府県・振興局名と一致しない。")
}

# 旧マスタ (PDF 由来) の841地点が全て含まれることを見る。これが崩れたら
# 上位互換ではなくなっているので、乗り換えの前提から確認し直す。
stations_2024 <-
  readr::read_csv(
    here::here("inst", "extdata", "wbgt_stations2024.csv"),
    col_types = readr::cols(
      station_no = readr::col_integer(),
      .default = readr::col_skip()
    )
  )

if (!all(stations_2024$station_no %in% wbgt_stations$station_no)) {
  stop("旧マスタの地点が配布 CSV に含まれていない。")
}

usethis::use_data(wbgt_stations, overwrite = FALSE)
