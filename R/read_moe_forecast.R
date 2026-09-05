#' Read WBGT forecasts from the Ministry of the Environment WebAPI
#'
#' Retrieves forecast values by site, JMA-region prefecture code, or all
#' sites. Range searches are split recursively when the API reports that the
#' 25,000-record limit was exceeded.
#'
#' @param station_no A vector of AMeDAS site numbers. Mutually exclusive with
#'   `pref_cd`; when both are `NULL`, all sites are requested.
#' @param pref_cd A vector of the API's JMA-region prefecture codes. See
#'   [wbgt_pref_codes]. Mutually exclusive with `station_no`.
#' @param date_from,date_to Range of forecast issue times. Date, POSIXct, and
#'   parseable character values are accepted and interpreted in Japan
#'   Standard Time. Supply both or neither. Both ends are inclusive:
#'   forecasts issued at `date_to` itself are returned (measured against the
#'   live API on 2026-09-04; the manual does not say).
#'   `date_to` must be strictly later than `date_from`: the API accepts a
#'   degenerate range, but a date without a time becomes midnight, so an
#'   equal pair would silently return the single record at 00:00 rather
#'   than the day it reads as. For one instant, ask for a one-second
#'   range (`"2026-09-01 12:00:00"` to `"2026-09-01 12:00:01"`).
#' @param origin_date One forecast issue time. Mutually exclusive with
#'   `date_from` and `date_to`.
#' @param fixed_time Optional issue time in `"HHMMSS"` format for range
#'   searches.
#' @param max_span Optional stride between requests, as a positive number of
#'   seconds or a `difftime`. Consecutive requests share their boundary
#'   instant, so a request spans one second more than the stride. The default
#'   sends the full range first and only splits after a limit error.
#' @return A tibble with `reference_time`, `wbgt_no`, `forecast_val`,
#'   `forecast_time`, and `flag`. `forecast_val` is the upstream integer value
#'   in degrees Celsius multiplied by 10 and is not converted by this
#'   function.
#' @examples
#' \dontrun{
#' read_moe_forecast(station_no = 44132, origin_date = "2026-09-01 00:00:00")
#' }
#' @export
read_moe_forecast <- function(
  station_no = NULL,
  pref_cd = NULL,
  date_from = NULL,
  date_to = NULL,
  origin_date = NULL,
  fixed_time = NULL,
  max_span = NULL
) {
  query <- moe_api_location(station_no, pref_cd)
  fixed_time <- moe_api_fixed_time(fixed_time)
  has_range <- !is.null(date_from) || !is.null(date_to)
  has_origin <- !is.null(origin_date)

  if (has_range && has_origin) {
    rlang::abort(
      "Supply either `date_from` and `date_to`, or `origin_date`, not both."
    )
  } else if (has_range) {
    if (is.null(date_from) || is.null(date_to)) {
      rlang::abort("Supply both `date_from` and `date_to` for a range search.")
    }
    from <- moe_api_datetime(date_from, "date_from")
    to <- moe_api_datetime(date_to, "date_to")
    if (to <= from) {
      rlang::abort("`date_to` must be later than `date_from`.")
    }
    query$date_search_type <- 1L
    if (!is.null(fixed_time)) {
      query$fixed_time <- fixed_time
    }
    moe_api_collect(
      endpoint = "getForecastData",
      query = query,
      from = from,
      to = to,
      from_param = "range_date_from",
      to_param = "range_date_to",
      parser = parse_moe_forecast,
      key = c("wbgt_no", "reference_time", "forecast_time"),
      max_span = max_span
    )
  } else if (has_origin) {
    if (!is.null(fixed_time)) {
      rlang::abort("`fixed_time` is only valid for range searches.")
    }
    if (!is.null(max_span)) {
      rlang::abort("`max_span` is only valid for range searches.")
    }
    query$date_search_type <- 3L
    query$forecast_origin_date <-
      origin_date |>
      moe_api_datetime("origin_date") |>
      moe_api_format_datetime()
    body <- moe_api_perform("getForecastData", query)
    classification <- moe_api_classify(body)
    if (classification == "success") {
      parse_moe_forecast(body)
    } else if (classification == "error") {
      moe_api_abort_application(body)
    } else if (classification == "threshold") {
      rlang::abort(
        "The API result exceeds 25,000 records for one issue time; narrow the location selection."
      )
    } else {
      rlang::abort("Internal error while classifying an API response.")
    }
  } else {
    rlang::abort("Supply either `date_from` and `date_to`, or `origin_date`.")
  }
}

parse_moe_forecast <- function(body) {
  if (is.null(body$data)) {
    rlang::abort("The forecast response has no `data` field.")
  }
  if (length(body$data) == 0L) {
    return(tibble::tibble(
      reference_time = as.POSIXct(character(), tz = moe_api_timezone),
      wbgt_no = integer(),
      forecast_val = numeric(),
      forecast_time = as.POSIXct(character(), tz = moe_api_timezone),
      flag = integer()
    ))
  }
  data <- tibble::as_tibble(body$data)
  required <- c(
    "reference_time",
    "wbgt_no",
    "forecast_val",
    "forecast_time",
    "flag"
  )
  if (!all(required %in% names(data))) {
    rlang::abort("The forecast response is missing required fields.")
  }
  data |>
    dplyr::transmute(
      reference_time = moe_api_parse_response_datetime(
        reference_time,
        "reference_time"
      ),
      wbgt_no = moe_api_parse_number(wbgt_no, "wbgt_no", integer = TRUE),
      forecast_val = moe_api_parse_number(forecast_val, "forecast_val"),
      forecast_time = moe_api_parse_response_datetime(
        forecast_time,
        "forecast_time"
      ),
      flag = moe_api_parse_number(flag, "flag", integer = TRUE)
    )
}
