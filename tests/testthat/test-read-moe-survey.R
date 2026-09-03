test_that("survey response strings are parsed as numeric without conversion", {
  body <- api_fixture_body("survey-success.json")
  result <- moewbgt:::parse_moe_survey(body)

  expect_s3_class(result, "tbl_df")
  expect_s3_class(result$wbgt_date, "POSIXct")
  expect_identical(result$wbgt_no, c(11001L, 11001L))
  expect_identical(result$wbgt_class, c(0L, 0L))
  expect_identical(result$wbgt_WI, c(1, 1))
  expect_identical(result$wbgt_WO, c(9.9, 9.1))
  expect_identical(result$wbgt_Tw, c(9.7, 9))
  expect_identical(result$wbgt_Tg, c(10, 9.3))
  expect_identical(attr(result$wbgt_date, "tzone"), "Asia/Tokyo")
})

test_that("survey infers all-sites mode and honours initial max_span", {
  requests <- character()
  mock <- function(req) {
    requests <<- c(requests, req$url)
    api_fixture_response("survey-success.json")
  }
  result <- httr2::with_mocked_responses(
    mock,
    read_moe_survey(
      date_from = "2012-06-01 00:00:00",
      date_to = "2012-06-01 04:00:00",
      max_span = as.difftime(2, units = "hours")
    )
  )

  expect_equal(nrow(result), 2L)
  expect_length(requests, 2L)
  expect_true(all(grepl("location_type=3", requests, fixed = TRUE)))
  expect_true(all(grepl("data_type=0&data_type=1", requests, fixed = TRUE)))
  expect_false(any(grepl(
    "date_from=20120601040000&date_to=20120601040000",
    requests,
    fixed = TRUE
  )))
})

test_that("max_span cannot round down to a zero-second interval", {
  expect_error(
    read_moe_survey(
      date_from = "2012-06-01 00:00:00",
      date_to = "2012-06-01 04:00:00",
      max_span = 0.5
    ),
    "at least one second"
  )
})

test_that("survey parser rejects malformed success responses", {
  expect_error(
    moewbgt:::parse_moe_survey(list(status = "success")),
    "no `data` field"
  )
})
