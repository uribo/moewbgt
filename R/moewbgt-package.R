#' @keywords internal
"_PACKAGE"

# Column names reached through data masking and tidy selection. R CMD check
# sees them as undefined globals because they only exist inside the data frame
# being piped. Declaring them once here rather than with a `col <- NULL` line
# at the top of each function keeps the list in a single place; add to it when
# a new column name is referenced without quoting.
#
# `Date` and `Time` are the upstream CSV's own capitalised headers, and `...1`
# is readr's placeholder for an unnamed first column -- both are quirks of the
# source files rather than names this package chose.
utils::globalVariables(
  c(
    "...1",
    "Date",
    "Time",
    "datetime",
    "station",
    "station_no",
    "time",
    "type",
    "wbgt"
  )
)
