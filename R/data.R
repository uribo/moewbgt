#' Region and prefecture codes used by the Ministry of the Environment WebAPI
#'
#' A lookup table for the regional and prefecture/subprefecture codes accepted
#' by `getForecastData` and `getSurveyData`. The prefecture codes follow Japan
#' Meteorological Agency numbering rather than JIS prefecture codes, so
#' Hokkaido is divided into subprefectures and Okinawa uses the combined code
#' 9194. The grouping into regions is the WebAPI's own and does not always
#' match the Agency's forecast regions.
#'
#' Yamaguchi (81) belongs to Chugoku (8), not Kyushu (10), even though its
#' code falls in the 80s block that every Kyushu prefecture uses. The WebAPI
#' departs from the Japan Meteorological Agency here, which places Yamaguchi
#' in its northern Kyushu forecast region.
#'
#' @format A tibble with 60 rows and four columns:
#' \describe{
#'   \item{area_cd}{Integer regional code from 1 to 11.}
#'   \item{area_name}{Japanese regional name.}
#'   \item{pref_cd}{Integer prefecture or subprefecture code.}
#'   \item{pref_name}{Japanese prefecture or subprefecture name.}
#' }
#' @source Prefecture and subprefecture codes and names come from the Ministry
#'   of the Environment, Heat Illness Prevention Information Site WebAPI
#'   specification, version 1.1, section 2-1,
#'   \url{https://www.wbgt.env.go.jp/man15NH/wbgt_data_api_service_manual.pdf}.
#'   That section does not state which region each prefecture belongs to, so
#'   `area_cd` was taken from the `area_cd` field of `getSurveyData` responses.
"wbgt_pref_codes"

#' Ministry of the Environment WBGT observation site master
#'
#' The master table of sites for which the Heat Illness Prevention Information
#' site publishes WBGT values. It is the successor to the
#' `wbgt_stations{2020,2022,2023,2024}.csv` files in `inst/extdata`, which were
#' extracted from the service manual PDFs; the Ministry now distributes the
#' master as a CSV, and that file is a superset of the 841 sites those
#' snapshots carry.
#'
#' All 865 sites are kept, including the 24 that have been withdrawn, because
#' historical values still reference them. A site is currently served when
#' `end_date` is `NA`; 841 sites are.
#'
#' `station_no` is the same identifier the WebAPI returns as `wbgt_no`, so it
#' joins to the output of [read_moe_survey()] and [read_moe_forecast()]
#' directly. [read_moe_wbgt()] carries the same number as a character column,
#' which has to be coerced before joining. `area_cd` and `pref_cd` come from
#' [wbgt_pref_codes] and are the codes the WebAPI functions accept.
#'
#' @format A tibble with 865 rows and 18 columns:
#' \describe{
#'   \item{area_cd}{Integer regional code from 1 to 11.}
#'   \item{area_name}{Japanese regional name.}
#'   \item{pref_cd}{Integer prefecture or subprefecture code.}
#'   \item{pref_name}{Japanese prefecture or subprefecture name.}
#'   \item{station_no}{Integer five-digit site number.}
#'   \item{station_name}{Japanese site name.}
#'   \item{kana}{Site name in hiragana.}
#'   \item{romaji}{Site name in upper-case romaji.}
#'   \item{address}{Japanese address of the site.}
#'   \item{latitude}{Latitude in decimal degrees.}
#'   \item{longitude}{Longitude in decimal degrees.}
#'   \item{start_date}{Date on which the site began to be served.}
#'   \item{end_date}{Date on which the site stopped being served, or `NA` while
#'     it is still served.}
#'   \item{old_station_no}{Integer site number used before a renumbering. It
#'     equals `station_no` except for the four sites that were renumbered.}
#'   \item{measure_start_date}{Date from which WBGT is measured on site rather
#'     than estimated, or `NA` where it never was. Forty-nine sites are
#'     measured, forty-seven of them currently.}
#'   \item{measure_end_date}{Date on which on-site measurement stopped, or `NA`
#'     while it continues.}
#'   \item{special_alert_exclusion_start_date}{Date from which the site is
#'     excluded from the heat stroke special alert decision, or `NA` where it
#'     is not excluded. Twenty-four sites are excluded from 2026-04-01.}
#'   \item{special_alert_exclusion_end_date}{Date on which the exclusion ends,
#'     or `NA` while it applies.}
#' }
#' @details Latitude and longitude are folded into decimal degrees from the
#'   degree and minute columns of the source file. Dates carrying the upstream
#'   sentinel `9999-99-99`, which marks an open-ended period, are `NA`. The
#'   source bytes are kept unchanged in
#'   `system.file("extdata", "wbgt_point_master-20260515.csv", package = "moewbgt")`.
#' @source Ministry of the Environment, Heat Illness Prevention Information
#'   site,
#'   \url{https://www.wbgt.env.go.jp/man15NH/wbgt_point_master-20260515.csv},
#'   published 2026-05-15. Earlier editions of the file are no longer served.
"wbgt_stations"
