test_that("wbgt_pref_codes contains the documented exceptional mappings", {
  expect_s3_class(wbgt_pref_codes, "tbl_df")
  expect_equal(nrow(wbgt_pref_codes), 60L)
  expect_equal(
    wbgt_pref_codes$area_cd[wbgt_pref_codes$pref_cd == 9194L],
    11L
  )
  # Yamaguchi (81) belongs to Chugoku (8), not Kyushu (10), even though its
  # code sits in the 80s block. Verified against the live getSurveyData
  # response at two timestamps; see data-raw/wbgt_pref_codes.R.
  expect_equal(
    wbgt_pref_codes$area_cd[wbgt_pref_codes$pref_cd == 81L],
    8L
  )
  expect_equal(
    wbgt_pref_codes$pref_name[wbgt_pref_codes$pref_cd == 17L],
    "\uff75\uff8e\uff70\uff82\uff78"
  )
})

test_that("wbgt_stations covers the served and withdrawn sites", {
  expect_s3_class(wbgt_stations, "tbl_df")
  expect_equal(nrow(wbgt_stations), 865L)
  expect_false(anyDuplicated(wbgt_stations$station_no) != 0L)
  # 841 sites are served; the other 24 carry the date they were withdrawn.
  # The upstream sentinel 9999-99-99 for an open-ended period becomes NA.
  expect_equal(sum(is.na(wbgt_stations$end_date)), 841L)
  expect_false(anyNA(wbgt_stations$start_date))
  # Forty-nine sites measure WBGT on site instead of estimating it, and two of
  # those stopped in 2012.
  expect_equal(sum(!is.na(wbgt_stations$measure_start_date)), 49L)
  expect_equal(
    sum(
      !is.na(wbgt_stations$measure_start_date) &
        is.na(wbgt_stations$measure_end_date)
    ),
    47L
  )
  # Four sites were renumbered; every other row repeats its own number.
  expect_equal(
    sum(wbgt_stations$old_station_no != wbgt_stations$station_no),
    4L
  )
})

test_that("wbgt_stations agrees with wbgt_pref_codes", {
  expect_setequal(wbgt_stations$pref_name, wbgt_pref_codes$pref_name)
  expect_setequal(wbgt_stations$area_name, wbgt_pref_codes$area_name)
  # The distributed master places Yamaguchi in Chugoku, which is what the
  # live getSurveyData response gave for pref_cd 81; see data-raw.
  expect_equal(
    unique(wbgt_stations$area_cd[wbgt_stations$pref_cd == 81L]),
    8L
  )
  expect_false(anyNA(wbgt_stations$area_cd))
})

test_that("wbgt_stations locates sites in Japan", {
  tokyo <- wbgt_stations[wbgt_stations$station_no == 44132L, ]
  expect_equal(tokyo$station_name, "\u6771\u4eac")
  expect_equal(tokyo$romaji, "TOKYO")
  expect_equal(tokyo$pref_cd, 44L)
  # Folded from the degree and minute columns of the source file.
  expect_equal(tokyo$latitude, 35 + 41.5 / 60, tolerance = 1e-6)
  expect_equal(tokyo$longitude, 139 + 45.0 / 60, tolerance = 1e-6)
  expect_true(all(wbgt_stations$latitude > 20 & wbgt_stations$latitude < 46))
  expect_true(
    all(wbgt_stations$longitude > 122 & wbgt_stations$longitude < 154)
  )
})
