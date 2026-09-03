test_that("forecast responses are parsed without unit conversion", {
  body <- api_fixture_body("forecast-success.json")
  result <- moewbgt:::parse_moe_forecast(body)

  expect_s3_class(result, "tbl_df")
  expect_s3_class(result$reference_time, "POSIXct")
  expect_identical(result$wbgt_no, c(11001L, 11001L))
  expect_identical(result$forecast_val, c(40, -10))
  expect_identical(result$flag, c(0L, 0L))
  expect_identical(attr(result$reference_time, "tzone"), "Asia/Tokyo")
})

test_that("forecast location and date modes are inferred from arguments", {
  requests <- character()
  mock <- function(req) {
    requests <<- c(requests, req$url)
    api_fixture_response("forecast-success.json")
  }
  result <- httr2::with_mocked_responses(
    mock,
    read_moe_forecast(
      pref_cd = c(14L, 9194L),
      origin_date = "2023-05-01 00:00:00"
    )
  )

  expect_equal(nrow(result), 2L)
  expect_match(requests, "location_type=2", fixed = TRUE)
  expect_match(requests, "pref_cds=14&pref_cds=9194", fixed = TRUE)
  expect_match(requests, "date_search_type=3", fixed = TRUE)
  expect_match(requests, "forecast_origin_date=20230501000000", fixed = TRUE)
})

test_that("forecast rejects ambiguous argument combinations", {
  expect_error(
    read_moe_forecast(
      station_no = 11001,
      pref_cd = 11,
      origin_date = "2023-05-01"
    ),
    "only one"
  )
  expect_error(
    read_moe_forecast(date_from = "2023-05-01"),
    "both `date_from` and `date_to`"
  )
  expect_error(read_moe_forecast(), "Supply either")
})

test_that("forecast parser rejects malformed success responses", {
  expect_error(
    moewbgt:::parse_moe_forecast(list(status = "success")),
    "no `data` field"
  )
})
