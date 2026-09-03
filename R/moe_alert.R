# The @importFrom rvest below looks redundant next to the rvest:: calls in the
# body, and it is -- for the code. It is there for R CMD check: .onLoad()
# rebinds read_moe_alert to its memoised wrapper, and the check's analysis of
# the installed namespace then no longer sees the rvest:: calls, so rvest is
# reported under "All declared Imports should be used". Removing the directive
# brings that NOTE back (confirmed 2026-09-03 by disabling the rebinding).
#' Read the heat stroke alert announcement record for a year
#'
#' Scrapes the table of heat stroke alert announcements published on the
#' Ministry of the Environment heat illness prevention information site. The
#' result is memoised for the session, so repeating a call for the same year
#' does not hit the network again.
#'
#' @param year Announcement year. Records begin in 2019; a year outside 2019
#'   to the current year is an error.
#' @return A tibble in the wide layout of the source table: one row per
#'   prefecture, one column per announcement slot. Pass it to
#'   [alert_to_long()] to get one row per prefecture and datetime.
#' @seealso [alert_to_long()]
#' @examples
#' \dontrun{
#' read_moe_alert(2024)
#' }
#'
#' @importFrom rvest read_html
#' @export
read_moe_alert <- function(year) {
  if (
    dplyr::between(year, 2019, lubridate::year(lubridate::today())) == FALSE
  ) {
    rlang::abort("The data is available only after 2019 to the present.")
  }
  if (lubridate::year(lubridate::today()) == year) {
    tgt_url <-
      "https://www.wbgt.env.go.jp/alert_record.php"
  } else {
    tgt_url <-
      glue::glue("https://www.wbgt.env.go.jp/alert_record_{year}.php")
  }
  x <-
    rvest::read_html(tgt_url)
  x |>
    rvest::html_nodes(css = "#maincontent > div > table") |>
    rvest::html_table() |>
    purrr::pluck(1)
}

# Memoise at load time, not at build time. Wrapping the definition directly
# (`read_moe_alert <- memoise::memoise(function(year) ...)`) runs memoise()
# while the package is being installed, so the cache is created once and
# serialised into the namespace: every session then shares a cache built on the
# machine that did the install. Doing it in .onLoad() gives each session its
# own. This lives next to the function it wraps so the ordering dependency is
# local rather than resting on the collation order of R/.
.onLoad <- function(libname, pkgname) {
  read_moe_alert <<- memoise::memoise(read_moe_alert)
}

#' Reshape an alert announcement table to one row per prefecture and datetime
#'
#' The source table is wide, with one column per announcement slot, and its
#' layout changed when the special alert was introduced: earlier years carry one announcement count column and two
#' slots a day, later years carry two and one slot a day. The shape is chosen
#' from the number of announcement count columns present, so the same call
#' works across years.
#'
#' @param df A table as returned by [read_moe_alert()].
#' @param year The year `df` describes. The source table's column headers omit
#'   it, so it has to be supplied to build the datetimes.
#' @return A tibble with a `datetime` column and one logical column per alert
#'   type (`alert`, and `special_alert` for years that have it), `TRUE` where
#'   an alert was announced.
#' @seealso [read_moe_alert()]
#' @examples
#' \dontrun{
#' alert_to_long(read_moe_alert(2024), 2024)
#' }
#'
#' @export
alert_to_long <- function(df, year) {
  alert_type_n <-
    colnames(df) |>
    stringr::str_count("\u767a\u8868\u56de\u6570") |>
    sum()
  if (alert_type_n == 1) {
    df <-
      df |>
      purrr::set_names(
        c(
          names(df)[1:2],
          paste0(
            year,
            "/",
            names(df)[3:ncol(df)],
            " ",
            paste0(c(5, 17), ":00:00")
          )
        )
      ) |>
      dplyr::slice(-1) |>
      tidyr::pivot_longer(
        cols = tidyselect::contains("/"),
        names_to = "datetime",
        values_to = "alert"
      ) |>
      dplyr::select(-2) |>
      readr::type_convert("ccc")
  } else if (alert_type_n == 2) {
    df <-
      df |>
      purrr::set_names(
        c(
          names(df)[1:3],
          paste0(
            rep(c("special_alert", "alert"), length(names(df)[4:ncol(df)]) / 2),
            "_",
            year,
            "/",
            names(df)[4:ncol(df)],
            " ",
            paste0(5, ":00:00")
          )
        )
      )
    df <-
      df[, -c(2, 3)] |>
      dplyr::slice(-1) |>
      tidyr::pivot_longer(
        -1,
        names_to = c(".value", "datetime"),
        names_pattern = "(.+)_(.+)"
      ) |>
      readr::type_convert("cccc")
  }
  df |>
    dplyr::mutate(datetime = lubridate::as_datetime(datetime)) |>
    dplyr::mutate(dplyr::across(
      tidyselect::contains("alert"),
      ~ dplyr::if_else(. == "\u25cf", TRUE, FALSE)
    ))
}
