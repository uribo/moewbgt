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
