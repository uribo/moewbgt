moe_api_base_url <- "https://www.wbgt.env.go.jp/api/v1"
moe_api_timezone <- "Asia/Tokyo"
moe_api_min_span <- 3600

moe_api_location <- function(station_no, pref_cd) {
  if (!is.null(station_no) && !is.null(pref_cd)) {
    rlang::abort("Supply only one of `station_no` and `pref_cd`.")
  } else if (!is.null(station_no)) {
    list(location_type = 1L, wbgt_nos = moe_api_ids(station_no, "station_no"))
  } else if (!is.null(pref_cd)) {
    list(location_type = 2L, pref_cds = moe_api_ids(pref_cd, "pref_cd"))
  } else {
    list(location_type = 3L)
  }
}

moe_api_ids <- function(x, arg) {
  if (!is.atomic(x) || length(x) == 0L || anyNA(x)) {
    rlang::abort(paste0(
      "`",
      arg,
      "` must be a non-empty vector without missing values."
    ))
  }
  # A factor is an integer vector wearing labels, so `as.numeric()` would
  # return its level codes: `factor("44132")` becomes 1. Those codes are
  # themselves plausible site numbers, so the API would answer about some
  # other place instead of refusing. Read the labels, which is what the
  # caller meant.
  if (is.factor(x)) {
    x <- as.character(x)
  }
  values <- suppressWarnings(as.numeric(x))
  if (anyNA(values) || any(values %% 1 != 0) || any(values < 0)) {
    rlang::abort(paste0("`", arg, "` must contain non-negative whole numbers."))
  }
  if (arg == "station_no" && any(values > 99999)) {
    rlang::abort("`station_no` values must be between 0 and 99999.")
  } else if (arg == "pref_cd" && any(values > 9999)) {
    rlang::abort("`pref_cd` values must be between 0 and 9999.")
  } else {
    format(values, scientific = FALSE, trim = TRUE)
  }
}

moe_api_datetime <- function(x, arg) {
  if (length(x) != 1L || is.na(x)) {
    rlang::abort(paste0(
      "`",
      arg,
      "` must be one non-missing date or datetime."
    ))
  }
  if (inherits(x, "POSIXt")) {
    value <- as.POSIXct(x, tz = moe_api_timezone)
  } else if (inherits(x, "Date")) {
    value <- as.POSIXct(
      format(x, "%Y-%m-%d"),
      format = "%Y-%m-%d",
      tz = moe_api_timezone
    )
  } else if (is.character(x)) {
    if (stringr::str_detect(x, "^[0-9]{4}-[0-9]{2}-[0-9]{2}$")) {
      input_format <- "%Y-%m-%d"
    } else if (
      stringr::str_detect(
        x,
        "^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}$"
      )
    ) {
      input_format <- "%Y-%m-%d %H:%M"
      x <- stringr::str_replace(x, "T", " ")
    } else if (
      stringr::str_detect(
        x,
        "^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}:[0-9]{2}$"
      )
    ) {
      input_format <- "%Y-%m-%d %H:%M:%S"
      x <- stringr::str_replace(x, "T", " ")
    } else if (
      stringr::str_detect(
        x,
        "^[0-9]{4}/[0-9]{2}/[0-9]{2} [0-9]{2}:[0-9]{2}(:[0-9]{2})?$"
      )
    ) {
      input_format <- if (nchar(x) == 16L) {
        "%Y/%m/%d %H:%M"
      } else {
        "%Y/%m/%d %H:%M:%S"
      }
    } else if (stringr::str_detect(x, "^[0-9]{14}$")) {
      input_format <- "%Y%m%d%H%M%S"
    } else {
      rlang::abort(
        paste0("`", arg, "` could not be parsed as a date or datetime.")
      )
    }
    value <- as.POSIXct(x, format = input_format, tz = moe_api_timezone)
  } else {
    value <- as.POSIXct(NA, tz = moe_api_timezone)
  }
  if (is.na(value)) {
    rlang::abort(paste0(
      "`",
      arg,
      "` could not be parsed as a date or datetime."
    ))
  }
  value
}

moe_api_format_datetime <- function(x) {
  format(x, "%Y%m%d%H%M%S", tz = moe_api_timezone)
}

moe_api_fixed_time <- function(x) {
  if (is.null(x)) {
    return(NULL)
  }
  if (length(x) != 1L || is.na(x)) {
    rlang::abort("`fixed_time` must be one non-missing HHMMSS value.")
  }
  if (is.numeric(x) && x >= 0 && x %% 1 == 0) {
    x <- sprintf("%06d", as.integer(x))
  }
  if (
    !is.character(x) ||
      !stringr::str_detect(x, "^(?:[01][0-9]|2[0-3])[0-5][0-9][0-5][0-9]$")
  ) {
    rlang::abort("`fixed_time` must use HHMMSS format.")
  }
  x
}

moe_api_span_seconds <- function(x) {
  if (is.null(x)) {
    return(NULL)
  }
  if (inherits(x, "difftime")) {
    x <- as.numeric(x, units = "secs")
  }
  if (!is.numeric(x) || length(x) != 1L || is.na(x) || x < 1) {
    rlang::abort(
      "`max_span` must be at least one second or an equivalent `difftime`."
    )
  }
  floor(x)
}

moe_api_request <- function(endpoint, query) {
  req <- httr2::request(paste0(moe_api_base_url, "/", endpoint))
  req <- rlang::exec(httr2::req_url_query, req, !!!query, .multi = "explode")
  req |>
    httr2::req_user_agent("moewbgt (https://github.com/uribo/moewbgt)") |>
    httr2::req_throttle(rate = 30 / 60) |>
    httr2::req_retry(max_tries = 3L, retry_on_failure = TRUE)
}

moe_api_perform <- function(endpoint, query) {
  moe_api_request(endpoint, query) |>
    httr2::req_perform() |>
    httr2::resp_body_json(simplifyVector = TRUE)
}

moe_api_classify <- function(body) {
  if (
    !is.list(body) || length(body$status) != 1L || !is.character(body$status)
  ) {
    rlang::abort("The API response has no scalar character `status` field.")
  }
  if (identical(body$status, "success")) {
    "success"
  } else if (identical(body$status, "error")) {
    message <- body$errMsg
    if (length(message) != 1L || !is.character(message)) {
      rlang::abort(
        "The API error response has no scalar character `errMsg` field."
      )
    }
    # The manual's threshold error begins with this clause. Match the stable
    # cause rather than the complete sentence so punctuation changes do not
    # turn a splittable request into a generic application error.
    threshold_text <-
      "\u691c\u7d22\u7d50\u679c\u304c\u95be\u5024\u4ee5\u4e0a\u3068\u306a\u3063\u305f\u305f\u3081"
    if (stringr::str_detect(message, stringr::fixed(threshold_text))) {
      "threshold"
    } else {
      "error"
    }
  } else {
    rlang::abort(paste0("Unexpected API response status: ", body$status))
  }
}

moe_api_abort_application <- function(body) {
  rlang::abort(paste0(
    "Ministry of the Environment WebAPI error: ",
    body$errMsg
  ))
}

moe_api_parse_number <- function(x, field, integer = FALSE) {
  value <- suppressWarnings(as.numeric(x))
  if (length(value) != length(x) || any(is.na(value) & !is.na(x))) {
    rlang::abort(paste0("The API returned a non-numeric `", field, "` value."))
  }
  if (integer && any(!is.na(value) & value %% 1 != 0)) {
    rlang::abort(paste0("The API returned a non-integer `", field, "` value."))
  }
  if (integer) {
    as.integer(value)
  } else {
    value
  }
}

moe_api_parse_response_datetime <- function(x, field) {
  value <- as.POSIXct(
    x,
    format = "%Y/%m/%d %H:%M:%S",
    tz = moe_api_timezone
  )
  if (any(is.na(value) & !is.na(x))) {
    rlang::abort(paste0("The API returned an invalid `", field, "` datetime."))
  }
  value
}

# Consecutive requests share their boundary instead of abutting, so
# `max_span` is a stride rather than a width. The manual never says whether
# `date_to` is inclusive, and only an overlap is correct under both
# readings: a shared instant is fetched twice at worst, which the
# `distinct()` in `moe_api_collect()` removes, whereas abutting ranges drop
# the boundary record outright if the API excludes `date_to` -- and drop it
# silently, so splitting would return fewer rows than the same unsplit
# request.
moe_api_intervals <- function(from, to, max_span) {
  if (is.null(max_span)) {
    return(list(list(from = from, to = to)))
  }
  intervals <- list()
  current <- from
  while (current < to) {
    interval_to <- min(current + max_span, to)
    intervals[[length(intervals) + 1L]] <- list(
      from = current,
      to = interval_to
    )
    current <- interval_to
  }
  if (length(intervals) == 0L) {
    list(list(from = from, to = to))
  } else {
    intervals
  }
}

moe_api_collect_interval <- function(
  endpoint,
  query,
  from,
  to,
  from_param,
  to_param,
  parser
) {
  interval_query <- query
  interval_query[[from_param]] <- moe_api_format_datetime(from)
  interval_query[[to_param]] <- moe_api_format_datetime(to)
  body <- moe_api_perform(endpoint, interval_query)
  classification <- moe_api_classify(body)

  if (classification == "success") {
    parser(body)
  } else if (classification == "error") {
    moe_api_abort_application(body)
  } else if (classification == "threshold") {
    span <- as.numeric(difftime(to, from, units = "secs"))
    if (span <= moe_api_min_span) {
      rlang::abort(
        paste(
          "The API result still exceeds 25,000 records for a one-hour range.",
          "Narrow the location selection or use `fixed_time` for forecasts."
        )
      )
    }
    # The halves share the midpoint for the same reason the strides overlap
    # above: an unknown boundary rule must not be able to lose a record.
    midpoint <- from + floor(span / 2)
    parts <- list(
      moe_api_collect_interval(
        endpoint,
        query,
        from,
        midpoint,
        from_param,
        to_param,
        parser
      ),
      moe_api_collect_interval(
        endpoint,
        query,
        midpoint,
        to,
        from_param,
        to_param,
        parser
      )
    )
    purrr::list_rbind(parts)
  } else {
    rlang::abort("Internal error while classifying an API response.")
  }
}

moe_api_collect <- function(
  endpoint,
  query,
  from,
  to,
  from_param,
  to_param,
  parser,
  key,
  max_span = NULL
) {
  max_span <- moe_api_span_seconds(max_span)
  intervals <- moe_api_intervals(from, to, max_span)
  data <-
    intervals |>
    purrr::map(
      \(interval) {
        moe_api_collect_interval(
          endpoint = endpoint,
          query = query,
          from = interval$from,
          to = interval$to,
          from_param = from_param,
          to_param = to_param,
          parser = parser
        )
      }
    ) |>
    purrr::list_rbind()
  data |>
    dplyr::distinct(
      dplyr::across(tidyselect::all_of(key)),
      .keep_all = TRUE
    )
}
