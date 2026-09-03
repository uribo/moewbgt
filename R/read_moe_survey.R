#' Read observed WBGT values from the Ministry of the Environment WebAPI
#'
#' Retrieves estimated or measured observed values by site, JMA-region
#' prefecture code, or all sites. Requests are split recursively when the API
#' reports that the 25,000-record limit was exceeded.
#'
#' @param station_no A vector of AMeDAS site numbers. Mutually exclusive with
#'   `pref_cd`; when both are `NULL`, all sites are requested.
#' @param pref_cd A vector of the API's JMA-region prefecture codes. See
#'   [wbgt_pref_codes]. Mutually exclusive with `station_no`.
#' @param date_from,date_to Observation range. Date, POSIXct, and parseable
#'   character values are accepted and interpreted in Japan Standard Time.
#' @param data_type One or both of `0` (estimated) and `1` (measured).
#' @param max_span Optional stride between requests, as a positive number of
#'   seconds or a `difftime`. Consecutive requests share their boundary
#'   instant, so a request spans one second more than the stride. The default
#'   sends the full range first and only splits after a limit error.
#' @return A tibble containing the upstream fields. `wbgt_WO`, `wbgt_Tw`, and
#'   `wbgt_Tg` are degrees Celsius; `wbgt_WI` is the 0--4 data-quality code.
#'   Values are converted from JSON strings to numeric but are otherwise
#'   unchanged.
#' @examples
#' \dontrun{
#' read_moe_survey(
#'   station_no = 44132,
#'   date_from = "2026-09-01",
#'   date_to = "2026-09-02"
#' )
#' }
#' @export
read_moe_survey <- function(
  station_no = NULL,
  pref_cd = NULL,
  date_from,
  date_to,
  data_type = c(0L, 1L),
  max_span = NULL
) {
  query <- moe_api_location(station_no, pref_cd)
  if (
    !is.numeric(data_type) ||
      length(data_type) == 0L ||
      anyNA(data_type) ||
      any(!data_type %in% c(0L, 1L))
  ) {
    rlang::abort("`data_type` must contain 0, 1, or both.")
  }
  from <- moe_api_datetime(date_from, "date_from")
  to <- moe_api_datetime(date_to, "date_to")
  if (to <= from) {
    rlang::abort("`date_to` must be later than `date_from`.")
  }
  query$data_type <- as.integer(unique(data_type))
  moe_api_collect(
    endpoint = "getSurveyData",
    query = query,
    from = from,
    to = to,
    from_param = "date_from",
    to_param = "date_to",
    parser = parse_moe_survey,
    key = c("wbgt_no", "wbgt_date", "wbgt_class"),
    max_span = max_span
  )
}

parse_moe_survey <- function(body) {
  if (is.null(body$data)) {
    rlang::abort("The survey response has no `data` field.")
  }
  if (length(body$data) == 0L) {
    return(tibble::tibble(
      wbgt_no = integer(),
      wbgt_date = as.POSIXct(character(), tz = moe_api_timezone),
      wbgt_class = integer(),
      area_cd = integer(),
      pref_cd = integer(),
      wbgt_WI = numeric(),
      wbgt_WO = numeric(),
      wbgt_Tw = numeric(),
      wbgt_Tg = numeric()
    ))
  }
  data <- tibble::as_tibble(body$data)
  required <- c(
    "wbgt_no",
    "wbgt_date",
    "wbgt_class",
    "area_cd",
    "pref_cd",
    "wbgt_WI",
    "wbgt_WO",
    "wbgt_Tw",
    "wbgt_Tg"
  )
  if (!all(required %in% names(data))) {
    rlang::abort("The survey response is missing required fields.")
  }
  data |>
    dplyr::transmute(
      wbgt_no = moe_api_parse_number(wbgt_no, "wbgt_no", integer = TRUE),
      wbgt_date = moe_api_parse_response_datetime(wbgt_date, "wbgt_date"),
      wbgt_class = moe_api_parse_number(
        wbgt_class,
        "wbgt_class",
        integer = TRUE
      ),
      area_cd = moe_api_parse_number(area_cd, "area_cd", integer = TRUE),
      pref_cd = moe_api_parse_number(pref_cd, "pref_cd", integer = TRUE),
      wbgt_WI = moe_api_parse_number(wbgt_WI, "wbgt_WI"),
      wbgt_WO = moe_api_parse_number(wbgt_WO, "wbgt_WO"),
      wbgt_Tw = moe_api_parse_number(wbgt_Tw, "wbgt_Tw"),
      wbgt_Tg = moe_api_parse_number(wbgt_Tg, "wbgt_Tg")
    )
}
