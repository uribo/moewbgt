api_fixture_response <- function(name) {
  path <- testthat::test_path("fixtures", name)
  body <- paste(
    readLines(path, warn = FALSE, encoding = "UTF-8"),
    collapse = "\n"
  )
  httr2::response(
    status_code = 200,
    headers = list(`Content-Type` = "application/json; charset=utf-8"),
    body = charToRaw(enc2utf8(body))
  )
}

api_fixture_body <- function(name) {
  api_fixture_response(name) |>
    httr2::resp_body_json(simplifyVector = TRUE)
}
