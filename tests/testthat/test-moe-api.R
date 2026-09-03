test_that("moe_api_classify distinguishes threshold and validation errors", {
  expect_identical(
    moewbgt:::moe_api_classify(list(status = "success")),
    "success"
  )
  expect_identical(
    moewbgt:::moe_api_classify(list(
      status = "error",
      errMsg = paste0(
        "\u691c\u7d22\u7d50\u679c\u304c\u95be\u5024\u4ee5\u4e0a\u3068\u306a\u3063\u305f\u305f\u3081\u3001",
        "\u4e2d\u6b62\u3057\u307e\u3059\u3002"
      )
    )),
    "threshold"
  )
  expect_identical(
    moewbgt:::moe_api_classify(list(
      status = "error",
      errMsg = "\u5730\u70b9\u30bf\u30a4\u30d7\u306f\u5fc5\u9808\u9805\u76ee\u3067\u3059"
    )),
    "error"
  )
})

test_that("request query parameters use repeated names", {
  request <- moewbgt:::moe_api_request(
    "getSurveyData",
    list(
      data_type = c(0L, 1L),
      location_type = 1L,
      wbgt_nos = c("11001", "12011"),
      date_from = "20230501000000",
      date_to = "20230502000000"
    )
  )
  expect_match(request$url, "data_type=0&data_type=1", fixed = TRUE)
  expect_match(request$url, "wbgt_nos=11001&wbgt_nos=12011", fixed = TRUE)
})

test_that("input dates and datetimes are converted exactly in JST", {
  expect_identical(
    moewbgt:::moe_api_format_datetime(
      moewbgt:::moe_api_datetime(as.Date("2023-05-01"), "date_from")
    ),
    "20230501000000"
  )
  expect_identical(
    moewbgt:::moe_api_format_datetime(
      moewbgt:::moe_api_datetime("2023-05-01 12:30", "date_from")
    ),
    "20230501123000"
  )
  expect_identical(
    moewbgt:::moe_api_format_datetime(
      moewbgt:::moe_api_datetime("2023-05-01T12:30:45", "date_from")
    ),
    "20230501123045"
  )
  expect_error(
    moewbgt:::moe_api_datetime("2023-05-01 bad", "date_from"),
    "could not be parsed"
  )
})

test_that("validation errors abort without splitting", {
  requests <- character()
  mock <- function(req) {
    requests <<- c(requests, req$url)
    api_fixture_response("validation-error.json")
  }
  expect_error(
    httr2::with_mocked_responses(
      mock,
      read_moe_survey(
        station_no = 11001,
        date_from = "2012-06-01 00:00:00",
        date_to = "2012-06-01 04:00:00",
        data_type = 0L
      )
    ),
    "\u5730\u70b9\u30bf\u30a4\u30d7\u306e\u6307\u5b9a\u5024"
  )
  expect_length(requests, 1L)
})

test_that("threshold errors split the range and remove duplicate records", {
  requests <- character()
  mock <- function(req) {
    requests <<- c(requests, req$url)
    if (length(requests) == 1L) {
      api_fixture_response("threshold-error.json")
    } else {
      api_fixture_response("survey-success.json")
    }
  }
  result <- httr2::with_mocked_responses(
    mock,
    read_moe_survey(
      station_no = 11001,
      date_from = "2012-06-01 00:00:00",
      date_to = "2012-06-01 04:00:00",
      data_type = 0L
    )
  )
  expect_length(requests, 3L)
  expect_equal(nrow(result), 2L)
  expect_equal(
    nrow(dplyr::distinct(result, wbgt_no, wbgt_date, wbgt_class)),
    2L
  )
  expect_true(any(grepl("date_to=20120601015959", requests, fixed = TRUE)))
  expect_true(any(grepl("date_from=20120601020000", requests, fixed = TRUE)))
})

test_that("threshold errors at one hour abort", {
  requests <- character()
  mock <- function(req) {
    requests <<- c(requests, req$url)
    api_fixture_response("threshold-error.json")
  }
  expect_error(
    httr2::with_mocked_responses(
      mock,
      read_moe_survey(
        station_no = 11001,
        date_from = "2012-06-01 00:00:00",
        date_to = "2012-06-01 01:00:00",
        data_type = 0L
      )
    ),
    "one-hour range"
  )
  expect_length(requests, 1L)
})
