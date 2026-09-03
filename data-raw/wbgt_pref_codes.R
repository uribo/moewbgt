####################################
# 環境省 WebAPI の地方コード・都道府県コード対応表
#
# 典拠は WebAPI 仕様書 第1.1版 2-1節。地方コードと都府県・振興局の
# 対応は表の並び順で示されているため、地方ごとに明示して転記する。
# 山口は気象庁の区分に従い、九州（地方コード10）に含まれる。
####################################

wbgt_pref_codes <-
  tibble::tribble(
    ~area_cd , ~area_name , ~pref_cd , ~pref_name ,
     1L      , "北海道"      ,   11L    , "宗谷"       ,
     1L      , "北海道"      ,   12L    , "上川"       ,
     1L      , "北海道"      ,   13L    , "留萌"       ,
     1L      , "北海道"      ,   14L    , "石狩"       ,
     1L      , "北海道"      ,   15L    , "空知"       ,
     1L      , "北海道"      ,   16L    , "後志"       ,
     1L      , "北海道"      ,   17L    , "ｵﾎｰﾂｸ"    ,
     1L      , "北海道"      ,   18L    , "根室"       ,
     1L      , "北海道"      ,   19L    , "釧路"       ,
     1L      , "北海道"      ,   20L    , "十勝"       ,
     1L      , "北海道"      ,   21L    , "胆振"       ,
     1L      , "北海道"      ,   22L    , "日高"       ,
     1L      , "北海道"      ,   23L    , "渡島"       ,
     1L      , "北海道"      ,   24L    , "檜山"       ,
     2L      , "東北"       ,   31L    , "青森"       ,
     2L      , "東北"       ,   32L    , "秋田"       ,
     2L      , "東北"       ,   33L    , "岩手"       ,
     2L      , "東北"       ,   34L    , "宮城"       ,
     2L      , "東北"       ,   35L    , "山形"       ,
     2L      , "東北"       ,   36L    , "福島"       ,
     3L      , "関東"       ,   40L    , "茨城"       ,
     3L      , "関東"       ,   41L    , "栃木"       ,
     3L      , "関東"       ,   42L    , "群馬"       ,
     3L      , "関東"       ,   43L    , "埼玉"       ,
     3L      , "関東"       ,   44L    , "東京"       ,
     3L      , "関東"       ,   45L    , "千葉"       ,
     3L      , "関東"       ,   46L    , "神奈川"      ,
     4L      , "甲信"       ,   48L    , "長野"       ,
     4L      , "甲信"       ,   49L    , "山梨"       ,
     5L      , "東海"       ,   50L    , "静岡"       ,
     5L      , "東海"       ,   51L    , "愛知"       ,
     5L      , "東海"       ,   52L    , "岐阜"       ,
     5L      , "東海"       ,   53L    , "三重"       ,
     6L      , "北陸"       ,   54L    , "新潟"       ,
     6L      , "北陸"       ,   55L    , "富山"       ,
     6L      , "北陸"       ,   56L    , "石川"       ,
     6L      , "北陸"       ,   57L    , "福井"       ,
     7L      , "近畿"       ,   60L    , "滋賀"       ,
     7L      , "近畿"       ,   61L    , "京都"       ,
     7L      , "近畿"       ,   62L    , "大阪"       ,
     7L      , "近畿"       ,   63L    , "兵庫"       ,
     7L      , "近畿"       ,   64L    , "奈良"       ,
     7L      , "近畿"       ,   65L    , "和歌山"      ,
     8L      , "中国"       ,   66L    , "岡山"       ,
     8L      , "中国"       ,   67L    , "広島"       ,
     8L      , "中国"       ,   68L    , "島根"       ,
     8L      , "中国"       ,   69L    , "鳥取"       ,
     9L      , "四国"       ,   71L    , "徳島"       ,
     9L      , "四国"       ,   72L    , "香川"       ,
     9L      , "四国"       ,   73L    , "愛媛"       ,
     9L      , "四国"       ,   74L    , "高知"       ,
    10L      , "九州"       ,   81L    , "山口"       ,
    10L      , "九州"       ,   82L    , "福岡"       ,
    10L      , "九州"       ,   83L    , "大分"       ,
    10L      , "九州"       ,   84L    , "長崎"       ,
    10L      , "九州"       ,   85L    , "佐賀"       ,
    10L      , "九州"       ,   86L    , "熊本"       ,
    10L      , "九州"       ,   87L    , "宮崎"       ,
    10L      , "九州"       ,   88L    , "鹿児島"      ,
    11L      , "沖縄"       , 9194L    , "沖縄"
  )

if (nrow(wbgt_pref_codes) != 60L) {
  stop("都府県・振興局コード表は60行でなければならない。")
}

stations <-
  readr::read_csv(
    here::here("inst", "extdata", "wbgt_stations2024.csv"),
    col_types = readr::cols(
      area = readr::col_character(),
      station_no = readr::col_character(),
      .default = readr::col_skip()
    )
  )

# 仕様書の「ｵﾎｰﾂｸ」は地点マスタでは「網走・北見・紋別」。この1件だけを
# 明示的に対応させ、その他の表記は一切正規化しない。
pref_names_for_check <-
  wbgt_pref_codes |>
  dplyr::mutate(
    pref_name_check = dplyr::if_else(
      pref_name == "ｵﾎｰﾂｸ",
      "網走・北見・紋別",
      pref_name
    )
  )

if (!setequal(unique(stations$area), pref_names_for_check$pref_name_check)) {
  stop("仕様書と地点マスタの都府県・振興局名が一致しない。")
}

modal_prefixes <-
  stations |>
  dplyr::mutate(station_prefix = substr(station_no, 1L, 2L)) |>
  dplyr::count(area, station_prefix, name = "station_count") |>
  dplyr::slice_max(
    order_by = station_count,
    n = 1L,
    with_ties = FALSE,
    by = area
  )

prefix_check <-
  pref_names_for_check |>
  dplyr::left_join(
    modal_prefixes,
    by = dplyr::join_by(pref_name_check == area),
    relationship = "one-to-one"
  ) |>
  dplyr::mutate(
    prefix_matches = dplyr::if_else(
      pref_cd == 9194L,
      as.integer(station_prefix) %in% 91:94,
      as.integer(station_prefix) == pref_cd
    )
  )

if (
  any(is.na(prefix_check$prefix_matches)) ||
    !all(prefix_check$prefix_matches)
) {
  stop("地点番号の最頻接頭2桁が仕様書の都道府県コードと一致しない。")
}

usethis::use_data(wbgt_pref_codes, overwrite = FALSE)
