####################################
# 環境省 WebAPI の地方コード・都道府県コード対応表
#
# 都府県・振興局コードと名称の典拠は WebAPI 仕様書 第1.1版 2-1節。
# ただし同節は地方名の行と都府県の並びを別々に置くだけで、どの県が
# どの地方かは書いていない。並びは都道府県コードの単純な昇順であり、
# 地方の切れ目を含まないので、area_cd は仕様書からは読み取れない。
#
# そこで area_cd は生きた API に照会して確定させた。getSurveyData の
# レスポンスは area_cd と pref_cd を両方返す（仕様書 1-2-3）。全60件を
# 2026-09-01 00:00 と 2024-08-05 12:00 の2時点で照会し、両者は完全に
# 一致した（area_cd は時期に依存しない）。
#
# 山口（81）は中国（8）であって九州（10）ではない。気象庁は山口を
# 「九州北部地方（山口県を含む）」に入れる
# （ref. https://www.jma.go.jp/jma/kishou/know/yougo_hp/tiikimei.html）が、
# 環境省の WebAPI はこの1点で気象庁の区分に従っていない。コードが
# 80番台であることからも九州に見えるため、推測で振らないこと。
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
     8L      , "中国"       ,   81L    , "山口"       ,
     9L      , "四国"       ,   71L    , "徳島"       ,
     9L      , "四国"       ,   72L    , "香川"       ,
     9L      , "四国"       ,   73L    , "愛媛"       ,
     9L      , "四国"       ,   74L    , "高知"       ,
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
