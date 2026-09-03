# Boundary regression for the guideline bands. The migrated implementation cut
# the middle bands with between(x, 28, 30) and between(x, 25, 27), which left
# 30 < x < 31 and 27 < x < 28 matching no condition, so wbgt_guideline(30.5)
# returned NA. Expected values are written as Unicode escapes rather than read
# from a constant, so that the test cannot share a transcription error with the
# implementation.
danger <- "\u5371\u967a"
severe <- "\u53b3\u91cd\u8b66\u6212"
warning_ <- "\u8b66\u6212"
caution <- "\u6ce8\u610f"

test_that("wbgt_guideline() covers the gaps that used to return NA", {
  expect_equal(wbgt_guideline(30.5), severe)
  expect_equal(wbgt_guideline(27.5), warning_)
  expect_equal(wbgt_guideline(28.5), severe)
  expect_equal(wbgt_guideline(25.5), warning_)
})

test_that("wbgt_guideline() places the band edges on the lower bound", {
  expect_equal(wbgt_guideline(31), danger)
  expect_equal(wbgt_guideline(30), severe)
  expect_equal(wbgt_guideline(28), severe)
  expect_equal(wbgt_guideline(27), warning_)
  expect_equal(wbgt_guideline(25), warning_)
  expect_equal(wbgt_guideline(24.9), caution)
})

test_that("wbgt_guideline() is never NA for a finite input", {
  x <- seq(15, 40, by = 0.1)
  expect_false(any(is.na(wbgt_guideline(x))))
  expect_setequal(
    unique(wbgt_guideline(x)),
    c(caution, warning_, severe, danger)
  )
})

test_that("wbgt_guideline() propagates NA", {
  expect_identical(wbgt_guideline(NA_real_), NA_character_)
})

test_that("wbgt_guideline() honours lang", {
  expect_equal(wbgt_guideline(31, lang = "en"), "Danger")
  expect_equal(wbgt_guideline(30.5, lang = "en"), "Severe Warning")
  expect_equal(wbgt_guideline(27.5, lang = "en"), "Warning")
  expect_equal(wbgt_guideline(24.9, lang = "en"), "Caution")
  expect_error(wbgt_guideline(31, lang = "fr"))
})
