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

alert_to_long <- function(df, year) {
  alert_type_n <-
    colnames(df) |>
    stringr::str_count("発表回数") |>
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
        cols = contains("/"),
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
