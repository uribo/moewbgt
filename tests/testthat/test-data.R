test_that("wbgt_pref_codes contains the documented exceptional mappings", {
  expect_s3_class(wbgt_pref_codes, "tbl_df")
  expect_equal(nrow(wbgt_pref_codes), 60L)
  expect_equal(
    wbgt_pref_codes$area_cd[wbgt_pref_codes$pref_cd == 9194L],
    11L
  )
  expect_equal(
    wbgt_pref_codes$area_cd[wbgt_pref_codes$pref_cd == 81L],
    10L
  )
  expect_equal(
    wbgt_pref_codes$pref_name[wbgt_pref_codes$pref_cd == 17L],
    "\uff75\uff8e\uff70\uff82\uff78"
  )
})
